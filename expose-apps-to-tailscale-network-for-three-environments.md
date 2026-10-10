# Exponer las apps a la red de Tailscale en los 3 ambientes

Hace que las 5 apps de cada ambiente (15 en total) sean accesibles desde cualquier PC de la tailnet, con nombre propio y HTTPS automático, sin depender de la IP ni del puerto interno `3000`.

Cada VM tiene su propio cluster, así que se instala un Tailscale Kubernetes Operator en cada una y se agrega un `Ingress` por app. Los `Service` existentes (`ClusterIP`, puerto `3000`) no se tocan.

## 0. Punto de partida

Necesitas:

- Los kubeconfig de **administración** de las 3 VMs (`pcbox-kubeconfig-local.yaml`, `pcbox-kubeconfig-dev.yaml` y `pcbox-kubeconfig-prod.yaml`), generados en [generate-secret-values-for-github-action-for-three-environments.md](generate-secret-values-for-github-action-for-three-environments.md). Un usuario restringido no alcanza: el operator crea CRDs y ClusterRoles.
- `kubectl` y `helm` instalados en tu PC cliente.
- Tu PC cliente conectada a la misma tailnet que las VMs.
- Las 5 apps desplegadas en los 3 ambientes — [first-deploy-for-three-environments.md](first-deploy-for-three-environments.md).
- El namespace `tailscale` creado en cada VM — [create-namespaces-for-three-environments.md](create-namespaces-for-three-environments.md).

Los comandos se ejecutan desde la carpeta donde guardaste los kubeconfig.

## 1. Hostnames que se van a crear

Cada app recibe un nombre único en la tailnet: `<ambiente>-<app>`.

| App | Local | Dev | Prod |
|---|---|---|---|
| `iam` | `local-iam` | `dev-iam` | `prod-iam` |
| `iam-api` | `local-iam-api` | `dev-iam-api` | `prod-iam-api` |
| `infra-hub-api` | `local-infra-hub-api` | `dev-infra-hub-api` | `prod-infra-hub-api` |
| `ticket-hub` | `local-ticket-hub` | `dev-ticket-hub` | `prod-ticket-hub` |
| `ticket-hub-api` | `local-ticket-hub-api` | `dev-ticket-hub-api` | `prod-ticket-hub-api` |

La URL final es `https://<hostname>.tu-tailnet.ts.net`.

## 2. Crear los tags en la ACL de Tailscale

Se hace una sola vez para toda la tailnet.

Entra a [Access controls](https://login.tailscale.com/admin/acls) → **Definitions** → pestaña **Tags** y pulsa **Create tag** para cada uno que falte:

| Tag | Tag owner | Para qué sirve |
|---|---|---|
| `tag:k8s-operator` | tu usuario (tu email de Tailscale) | los operators |
| `tag:k8s` | `tag:k8s-operator` | los proxies que cada operator crea, uno por `Ingress` |
| `tag:continuous-integration` | `autogroup:admin` | los runners de GitHub Actions (ya debería existir; lo usa el workflow de deploy) |

Al terminar, la pestaña **Tags** debe listar los tres.

Sin `tag:k8s`, el operator se instala pero falla al crear cada proxy con `requested tags [tag:k8s] are invalid or not permitted (400)`.

## 3. Crear el OAuth client del operator

Se hace una sola vez. Se puede usar el mismo OAuth client en los 3 operators.

Es distinto al OAuth client de GitHub Actions: este lo usan los operators para crear nodos en la tailnet.

1. Entra a [Trust credentials](https://console.tailscale.com/admin/settings/trust-credentials).
2. **Credential → OAuth**. En **Description** pon `tailscale-k8s-operator` (es solo una referencia interna) y pulsa **Continue**.
3. En **Scopes** marca `write` en: **General → Services**, **Devices → Core** y **Keys → Auth Keys**.
4. En **Tags** asigna `tag:k8s-operator`.
5. Genera el cliente y copia el **Client ID** y el **Client Secret**. El secret solo se muestra una vez.

Estos valores no se cargan en GitHub. Se usan en el paso 5. No los commitees.

## 4. Habilitar MagicDNS y HTTPS

Se hace una sola vez.

En la [página DNS](https://console.tailscale.com/admin/dns) activa **MagicDNS** y **HTTPS Certificates**. Sin ellos no hay nombres ni certificados.

## 5. Instalar el operator en cada VM

Este paso se hace **desde tu PC cliente**, parado en la carpeta donde guardaste los kubeconfig (`pcbox-kubeconfig-local.yaml`, `pcbox-kubeconfig-dev.yaml` y `pcbox-kubeconfig-prod.yaml`). No entres por SSH a las VMs: `helm` y `kubectl` le hablan al cluster de cada VM a través de `--kubeconfig`, por la tailnet.

Agrega el repositorio de Helm una sola vez, en tu PC. Sirve para los 3 ambientes:

```bash
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update
```

Reemplaza `<TS_OAUTH_CLIENT_ID_OPERATOR>` y `<TS_OAUTH_SECRET_OPERATOR>` por los valores del paso 3. Cada operator lleva un nombre distinto en la tailnet.

### local

```bash
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --kubeconfig pcbox-kubeconfig-local.yaml \
  --namespace=tailscale \
  --set-string oauth.clientId="<TS_OAUTH_CLIENT_ID_OPERATOR>" \
  --set-string oauth.clientSecret="<TS_OAUTH_SECRET_OPERATOR>" \
  --set-string operatorConfig.hostname="local-tailscale-operator" \
  --wait

kubectl --kubeconfig pcbox-kubeconfig-local.yaml get pods -n tailscale
```

### dev

```bash
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --kubeconfig pcbox-kubeconfig-dev.yaml \
  --namespace=tailscale \
  --set-string oauth.clientId="<TS_OAUTH_CLIENT_ID_OPERATOR>" \
  --set-string oauth.clientSecret="<TS_OAUTH_SECRET_OPERATOR>" \
  --set-string operatorConfig.hostname="dev-tailscale-operator" \
  --wait

kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get pods -n tailscale
```

### prod

```bash
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --kubeconfig pcbox-kubeconfig-prod.yaml \
  --namespace=tailscale \
  --set-string oauth.clientId="<TS_OAUTH_CLIENT_ID_OPERATOR>" \
  --set-string oauth.clientSecret="<TS_OAUTH_SECRET_OPERATOR>" \
  --set-string operatorConfig.hostname="prod-tailscale-operator" \
  --wait

kubectl --kubeconfig pcbox-kubeconfig-prod.yaml get pods -n tailscale
```

En cada ambiente, el pod del operator debe quedar `Running`:

```
NAME                        READY   STATUS    RESTARTS   AGE
operator-5f8c7d9b6-abcde    1/1     Running   0          1m
```

## 6. Crear los Ingress

Cada `Ingress` le dice al operator qué `Service` exponer y con qué nombre.

> **Importante: límite de 10 cuentas cada 3 horas.** Cada `Ingress` crea un proxy, y cada proxy registra una cuenta nueva en Let's Encrypt para obtener su certificado HTTPS. Let's Encrypt permite solo **10 cuentas nuevas por IP cada 3 horas**, y los 3 ambientes salen a internet por la misma IP pública. Aquí se crean **15** (5 apps × 3 ambientes), así que los últimos 5 quedan bloqueados y sus URLs dan `ERR_TIMED_OUT` hasta que pase el bloqueo.
>
> Es normal y se resuelve solo. Si pasa:
>
> 1. **Espera, sin tocar nada.** Los proxies reintentan automáticamente cuando termina el bloqueo (el log indica la hora exacta en `retry after`, en UTC).
> 2. **No borres ni recrees los `Ingress` ni los proxies.** Cada proxy nuevo registra otra cuenta, consume el cupo y alarga la espera.
>
> Una vez emitido el certificado de un proxy, no vuelve a consumir cupo: abrir los sitios y renovar los certificados no cuenta. Para evitar la espera, crea como máximo 10 `Ingress` y los otros 5 al menos 3 horas después.

### local

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam
  namespace: iam
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam
      port:
        number: 3000
  tls:
    - hosts:
        - local-iam
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam-api
  namespace: iam-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam-api
      port:
        number: 3000
  tls:
    - hosts:
        - local-iam-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: infra-hub-api
  namespace: infra-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: infra-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - local-infra-hub-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub
  namespace: ticket-hub
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub
      port:
        number: 3000
  tls:
    - hosts:
        - local-ticket-hub
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub-api
  namespace: ticket-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - local-ticket-hub-api
EOF
```

### dev

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam
  namespace: iam
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam
      port:
        number: 3000
  tls:
    - hosts:
        - dev-iam
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam-api
  namespace: iam-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam-api
      port:
        number: 3000
  tls:
    - hosts:
        - dev-iam-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: infra-hub-api
  namespace: infra-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: infra-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - dev-infra-hub-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub
  namespace: ticket-hub
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub
      port:
        number: 3000
  tls:
    - hosts:
        - dev-ticket-hub
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub-api
  namespace: ticket-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - dev-ticket-hub-api
EOF
```

### prod

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam
  namespace: iam
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam
      port:
        number: 3000
  tls:
    - hosts:
        - prod-iam
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: iam-api
  namespace: iam-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: iam-api
      port:
        number: 3000
  tls:
    - hosts:
        - prod-iam-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: infra-hub-api
  namespace: infra-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: infra-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - prod-infra-hub-api
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub
  namespace: ticket-hub
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub
      port:
        number: 3000
  tls:
    - hosts:
        - prod-ticket-hub
EOF
```

```bash
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ticket-hub-api
  namespace: ticket-hub-api
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: ticket-hub-api
      port:
        number: 3000
  tls:
    - hosts:
        - prod-ticket-hub-api
EOF
```

Cada operator crea un Pod proxy por cada `Ingress`, que se une a la tailnet como un nodo nuevo. Tarda unos segundos.

Si aplicaste los `Ingress` antes de tener listos los tags, el operator reintenta cada vez más espaciado. Para forzar el reintento:

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml rollout restart deployment/operator -n tailscale
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml rollout restart deployment/operator -n tailscale
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml rollout restart deployment/operator -n tailscale
```

## 7. Verificar

### Ingress con hostname asignado

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml get ingress -A
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml get ingress -A
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml get ingress -A
```

Cada comando debe mostrar 5 filas (una por app, en los namespaces `iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api`) con `ADDRESS` completo, 15 en total. Si no aparece ninguna fila, falta aplicar los Ingress de la sección 6. Puede tardar un minuto. Ejemplo con `dev`:

```
iam              iam              tailscale   *   dev-iam.tu-tailnet.ts.net              80, 443   1m
iam-api          iam-api          tailscale   *   dev-iam-api.tu-tailnet.ts.net          80, 443   1m
infra-hub-api    infra-hub-api    tailscale   *   dev-infra-hub-api.tu-tailnet.ts.net    80, 443   1m
ticket-hub       ticket-hub       tailscale   *   dev-ticket-hub.tu-tailnet.ts.net       80, 443   1m
ticket-hub-api   ticket-hub-api   tailscale   *   dev-ticket-hub-api.tu-tailnet.ts.net   80, 443   1m
```

Si `ADDRESS` queda vacío, revisa los logs del operator de ese ambiente:

```bash
kubectl --kubeconfig pcbox-kubeconfig-local.yaml logs -n tailscale deploy/operator
kubectl --kubeconfig pcbox-kubeconfig-dev.yaml logs -n tailscale deploy/operator
kubectl --kubeconfig pcbox-kubeconfig-prod.yaml logs -n tailscale deploy/operator
```

### Nodos en la tailnet

```bash
tailscale status | grep -E "(local|dev|prod)-"
```

Debe haber 15 nodos de apps y 3 de operators (`local-tailscale-operator`, `dev-tailscale-operator` y `prod-tailscale-operator`), además de las 3 VMs `pcbox-*`.

### Acceso desde el navegador

Desde cualquier PC de la tailnet, sin VPN adicional ni puertos abiertos:

```
https://dev-iam.tu-tailnet.ts.net
https://dev-ticket-hub.tu-tailnet.ts.net
```

Para comprobarlo desde la terminal:

```bash
curl -sI https://dev-iam.tu-tailnet.ts.net | head -n 1
```

Debe responder una línea `HTTP/2` con un código de la app (por ejemplo `200` o `302`). Un error de conexión o de certificado indica que falta MagicDNS, HTTPS Certificates o que la PC no está en la tailnet (`tailscale status`).

> **Si una URL da `ERR_TIMED_OUT` o tarda demasiado, y las demás sí abren:** probablemente se superó el límite de **10 cuentas cada 3 horas** de Let's Encrypt (ver la nota de la sección 6). Se crean 15 proxies, así que los últimos 5 todavía no tienen certificado. **Espera sin tocar nada** y no borres ni recrees `Ingress` ni proxies.
>
> Para confirmarlo, mira los logs del proxy. Reemplaza `<proxy>` por el nombre del pod que muestra `get pods -n tailscale` (por ejemplo `ts-iam-xxxxx-0`):
>
> ```bash
> kubectl --kubeconfig pcbox-kubeconfig-prod.yaml get pods -n tailscale
> kubectl --kubeconfig pcbox-kubeconfig-prod.yaml logs -n tailscale <proxy> --tail=30
> ```
>
> Si aparece `429 urn:ietf:params:acme:error:rateLimited ... retry after <hora> UTC`, espera hasta esa hora. Después el proxy obtiene el certificado solo y la URL abre.



## 8. Datos que quedan

| Dato | Qué es | Para qué sirve |
|---|---|---|
| `TS_OAUTH_CLIENT_ID_OPERATOR` y `TS_OAUTH_SECRET_OPERATOR` | Credenciales de los operators | Reinstalar un operator (paso 5). No se commitean |
| `<ambiente>-<app>.tu-tailnet.ts.net` | Hostname de cada app | URL de acceso desde la tailnet |

## Nota de seguridad

Las 3 APIs (`iam-api`, `infra-hub-api`, `ticket-hub-api`) quedan alcanzables desde toda la tailnet. Con las ACL por defecto, todos los nodos se ven entre sí. Si solo quieres exponer los frontends (`iam` y `ticket-hub`), omite las APIs en el paso 6.
