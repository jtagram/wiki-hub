# Implementar observabilidad (Loki y Grafana) en los 3 ambientes

Instala lo mínimo para **ver los logs** de las apps en cada ambiente: Loki (guarda), Alloy (recolecta los logs de los pods) y Grafana (los muestra). No incluye métricas, trazas ni alertas.

Cada VM tiene su propio cluster, así que se instala todo en cada una, en el namespace `observability`.

## 0. Punto de partida

Necesitas:

- Los kubeconfig de **administración** de las 3 VMs (`pcbox-kubeconfig-local.yaml`, `pcbox-kubeconfig-dev.yaml` y `pcbox-kubeconfig-prod.yaml`), generados en [generate-secret-values-for-github-action-for-three-environments.md](generate-secret-values-for-github-action-for-three-environments.md).
- `kubectl` y `helm` en tu PC cliente, conectada a la tailnet.
- El addon `hostpath-storage` habilitado en las 3 VMs (se habilita en [create-databases-for-three-environments.md](create-databases-for-three-environments.md)).
- Para entrar a Grafana por URL: el operator de Tailscale instalado en las 3 VMs — [expose-apps-to-tailscale-network-for-three-environments.md](expose-apps-to-tailscale-network-for-three-environments.md).

Todos los comandos se ejecutan desde tu PC cliente, en la carpeta donde guardaste los kubeconfig. No entres por SSH a las VMs: `helm` y `kubectl` hablan con el cluster de cada VM a través de `--kubeconfig`, por la tailnet.

## 1. Agregar los repositorios de Helm

Se hace una sola vez, en tu PC cliente (no dentro de las VMs). Sirve para los 3 ambientes:

```bash
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

- `grafana-community`: Loki y Grafana. El repositorio `grafana` quedó en desuso para estos dos charts.
- `grafana`: solo Alloy.

## 2. Crear los archivos de valores

Se crean una sola vez y sirven para los 3 ambientes. Guárdalos en la misma carpeta de los kubeconfig.

### `loki-values.yaml`

Loki en modo monolítico (1 pod), con los datos en disco local y 7 días de retención.

```bash
cat > loki-values.yaml <<'EOF'
deploymentMode: Monolithic

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
  limits_config:
    retention_period: 72h
  compactor:
    retention_enabled: true
    delete_request_store: filesystem

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    storageClass: microk8s-hostpath
    size: 2Gi

memberlist:
  service:
    publishNotReadyAddresses: true

gateway:
  enabled: false
chunksCache:
  enabled: false
resultsCache:
  enabled: false
lokiCanary:
  enabled: false
test:
  enabled: false

backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0
ingester:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
distributor:
  replicas: 0
compactor:
  replicas: 0
indexGateway:
  replicas: 0
bloomPlanner:
  replicas: 0
bloomBuilder:
  replicas: 0
bloomGateway:
  replicas: 0

sidecar:
  rules:
    enabled: false
EOF
```

### `alloy-values.yaml`

Un Alloy por VM que lee los logs de todos los pods y los envía a Loki, etiquetados con `namespace`, `pod`, `container` y `app`.

```bash
cat > alloy-values.yaml <<'EOF'
controller:
  type: daemonset

alloy:
  configMap:
    content: |
      discovery.kubernetes "pod" {
        role = "pod"
        selectors {
          role  = "pod"
          field = "spec.nodeName=" + coalesce(sys.env("HOSTNAME"), constants.hostname)
        }
      }

      discovery.relabel "pod_logs" {
        targets = discovery.kubernetes.pod.targets

        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label  = "namespace"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label  = "pod"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_container_name"]
          target_label  = "container"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
          target_label  = "app"
        }
      }

      loki.source.kubernetes "pod_logs" {
        targets    = discovery.relabel.pod_logs.output
        forward_to = [loki.write.default.receiver]
      }

      loki.write "default" {
        endpoint {
          url = "http://loki.observability.svc.cluster.local:3100/loki/api/v1/push"
        }
      }
EOF
```

### `grafana-values.yaml`

Grafana con Loki ya conectado como fuente de datos y la contraseña de administrador tomada de un Secret.

```bash
cat > grafana-values.yaml <<'EOF'
admin:
  existingSecret: grafana-admin
  userKey: admin-user
  passwordKey: admin-password

persistence:
  enabled: true
  storageClassName: microk8s-hostpath
  size: 500Mi

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki.observability.svc.cluster.local:3100
        isDefault: true
EOF
```

## 3. Instalar en cada ambiente

En cada ambiente: crear el namespace, crear el Secret de Grafana, e instalar Loki, Alloy y Grafana **en ese orden**.

Las versiones de los charts de Loki (`18.15.1`) y Grafana (`13.5.1`) quedan fijas con `--version`: son las últimas publicadas al escribir este instructivo y las contra las que se escribieron los archivos de valores. Sin fijarlas, un chart más nuevo podría cambiar los nombres de los valores.

La contraseña de Grafana se genera en el momento y se imprime una sola vez en la terminal. **Guárdala.** Si la pierdes, se recupera desde el Secret:

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml get secret grafana-admin -n observability -o jsonpath='{.data.admin-password}' | base64 -d
```

### local

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml create namespace observability

GRAFANA_PASSWORD=$(openssl rand -base64 24)
echo "$GRAFANA_PASSWORD"

kubectl --kubeconfig pcbox-kubeconfig-local.yaml create secret generic grafana-admin \
  --namespace observability \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$GRAFANA_PASSWORD"

helm upgrade --install loki grafana-community/loki \
  --kubeconfig pcbox-kubeconfig-local.yaml \
  --namespace observability \
  --version 18.15.1 \
  -f loki-values.yaml \
  --wait --timeout 10m

helm upgrade --install alloy grafana/alloy \
  --kubeconfig pcbox-kubeconfig-local.yaml \
  --namespace observability \
  -f alloy-values.yaml \
  --wait

helm upgrade --install grafana grafana-community/grafana \
  --kubeconfig pcbox-kubeconfig-local.yaml \
  --namespace observability \
  --version 13.5.1 \
  -f grafana-values.yaml \
  --wait
```

### dev

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml create namespace observability

GRAFANA_PASSWORD=$(openssl rand -base64 24)
echo "$GRAFANA_PASSWORD"

kubectl --kubeconfig pcbox-kubeconfig-dev.yaml create secret generic grafana-admin \
  --namespace observability \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$GRAFANA_PASSWORD"

helm upgrade --install loki grafana-community/loki \
  --kubeconfig pcbox-kubeconfig-dev.yaml \
  --namespace observability \
  --version 18.15.1 \
  -f loki-values.yaml \
  --wait --timeout 10m

helm upgrade --install alloy grafana/alloy \
  --kubeconfig pcbox-kubeconfig-dev.yaml \
  --namespace observability \
  -f alloy-values.yaml \
  --wait

helm upgrade --install grafana grafana-community/grafana \
  --kubeconfig pcbox-kubeconfig-dev.yaml \
  --namespace observability \
  --version 13.5.1 \
  -f grafana-values.yaml \
  --wait
```

### prod

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml create namespace observability

GRAFANA_PASSWORD=$(openssl rand -base64 24)
echo "$GRAFANA_PASSWORD"

kubectl --kubeconfig pcbox-kubeconfig-prod.yaml create secret generic grafana-admin \
  --namespace observability \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$GRAFANA_PASSWORD"

helm upgrade --install loki grafana-community/loki \
  --kubeconfig pcbox-kubeconfig-prod.yaml \
  --namespace observability \
  --version 18.15.1 \
  -f loki-values.yaml \
  --wait --timeout 10m

helm upgrade --install alloy grafana/alloy \
  --kubeconfig pcbox-kubeconfig-prod.yaml \
  --namespace observability \
  -f alloy-values.yaml \
  --wait

helm upgrade --install grafana grafana-community/grafana \
  --kubeconfig pcbox-kubeconfig-prod.yaml \
  --namespace observability \
  --version 13.5.1 \
  -f grafana-values.yaml \
  --wait
```

## 4. Exponer Grafana a la tailnet

Solo se expone Grafana. Loki y Alloy quedan internos al cluster.

| Local | Dev | Prod |
|---|---|---|
| `local-grafana` | `dev-grafana` | `prod-grafana` |

> Cada `Ingress` crea un proxy con su certificado de Let's Encrypt, y el límite es de **10 cuentas nuevas cada 3 horas** por IP. Si ya creaste los 15 `Ingress` de las apps hace poco, espera 3 horas antes de crear estos 3. Detalle en [expose-apps-to-tailscale-network-for-three-environments.md](expose-apps-to-tailscale-network-for-three-environments.md).

### local

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: observability
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: grafana
      port:
        number: 80
  tls:
    - hosts:
        - local-grafana
EOF
```

### dev

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: observability
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: grafana
      port:
        number: 80
  tls:
    - hosts:
        - dev-grafana
EOF
```

### prod

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: observability
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: grafana
      port:
        number: 80
  tls:
    - hosts:
        - prod-grafana
EOF
```

## 5. Verificar

### Pods

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml get pods -n observability
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get pods -n observability
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml get pods -n observability
```

En cada ambiente deben quedar 3 pods en `Running`: `loki-0`, `alloy-xxxxx` y `grafana-xxxxx`.

### PVC

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get pvc -n observability
```

Deben aparecer 2 volúmenes en `Bound`: el de Loki (2Gi) y el de Grafana (500Mi).

### Ingress

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get ingress -n observability
```

`ADDRESS` debe mostrar `dev-grafana.tu-tailnet.ts.net` (puede tardar un minuto).

### Logs llegando a Loki

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml logs -n observability daemonset/alloy --tail=20
```

No deben aparecer errores `connection refused` ni `429`. Si los hay, revisa que `loki-0` esté `Running`.

## 6. Ver los logs

1. Abre `https://<ambiente>-grafana.tu-tailnet.ts.net`.
2. Usuario `admin` y la contraseña que guardaste en el paso 3.
3. Menú **Explore** → fuente de datos **Loki**.
4. Escribe una consulta en modo **Code** y pulsa **Run query**.

Consultas útiles:

| Qué ver | Consulta |
|---|---|
| Todos los logs de una app | `{namespace="iam-api"}` |
| Solo errores de una API (pino) | `{namespace="iam-api"} \| json \| level >= 50` |
| Buscar un texto | `{namespace="iam-api"} \|= "Invalid credentials"` |
| Todo un request | `{namespace="iam-api"} \| json \| req_id="<id>"` |
| Logs de todas las apps | `{namespace=~"iam.*\|infra-hub-api\|ticket-hub.*"}` |

El campo `level` de pino es numérico: `30` info, `40` warn, `50` error, `60` fatal.

## 7. Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| Contraseña de `admin` de Grafana (una por ambiente) | Se generó en el paso 3 | Entrar a Grafana. Si la pierdes, léela del Secret `grafana-admin` (comando en el paso 3) |
| `<ambiente>-grafana.tu-tailnet.ts.net` | Hostname de Grafana | URL de acceso desde la tailnet |
| `loki-values.yaml`, `alloy-values.yaml`, `grafana-values.yaml` | Configuración de los charts | Reinstalar o actualizar con `helm upgrade --install` |

## Notas

- **`memberlist.service.publishNotReadyAddresses: true`:** sin esto Loki no arranca. Su servicio `loki-memberlist` solo publica el pod cuando está `Ready`, pero el pod necesita ese servicio para quedar `Ready`; Loki aborta tras 10 reintentos y se reinicia en bucle (síntoma: `loki-0` en `1/2` con `RESTARTS` creciendo y `no such host` para `loki-memberlist` en su log).
- **RAM de las VMs:** con 3 GB, MicroK8s junto con las apps y este stack dejó la VM saturada (`kubelite` reiniciándose, `kswapd0` activo). Las VMs necesitan al menos 4 GB. En `pcbox`: `multipass stop <vm>`, `multipass set local.<vm>.memory=4GiB`, `multipass start <vm>`.

- **Retención:** los logs se conservan 3 días (`retention_period: 72h`). Para cambiarlo, edita `loki-values.yaml` y ejecuta de nuevo el `helm upgrade --install loki ...` de cada ambiente.
- **Disco:** las VMs tienen solo 20 GB. Con `microk8s-hostpath` el tamaño del volumen (`2Gi`) es solo nominal y no se aplica como límite: lo que evita llenar el disco es la retención. Revisa el espacio con `df -h /` dentro de la VM, y si sube demasiado baja `retention_period`.
- **Sin autenticación en Loki:** solo es accesible dentro del cluster. No lo expongas a la tailnet.
- **Logs de la app:** Loki solo ve lo que las apps escriben en stdout/stderr. `iam-api` e `infra-hub-api` ya lo hacen en JSON con `nestjs-pino`.

<p align="right"><a href="set-up-the-ecosystem-jtagram.md">← Back</a></p>
