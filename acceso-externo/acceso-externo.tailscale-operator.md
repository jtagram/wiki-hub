# Exponer `iam` y `ticket-hub` con el Tailscale Operator

Instructivo para que `iam` y `ticket-hub` sean accesibles desde cualquier PC cliente de la tailnet, con un nombre propio (`iam.tu-tailnet.ts.net`, `ticket-hub.tu-tailnet.ts.net`) y HTTPS automático, sin depender de la IP ni el puerto interno del Service (`3000`).

Esto es infraestructura de **cluster**, no un cambio en los `Deployment` de las apps: instala un componente nuevo (el Tailscale Kubernetes Operator) y agrega un recurso `Ingress` por app. Los Service actuales (`ClusterIP`, puerto `3000`) no se tocan — el operator los usa como backend tal cual están.

## 0. Punto de partida

Vas a necesitar:

- El kubeconfig de administración generado en [`pcbox/pcbox.microk8s-setup.md`](../pcbox/pcbox.microk8s-setup.md), paso 2 (`~/pcbox-kubeconfig.yaml`) — el usuario restringido de [`pcbox/pcbox.microk8s-usuario-viewer-secretos.md`](../pcbox/pcbox.microk8s-usuario-viewer-secretos.md) no alcanza, porque instalar el operator crea namespaces, CRDs y ClusterRoles.
- `helm` instalado en tu PC cliente (no en `pcbox` — Helm se conecta al API server remoto igual que `kubectl`, a través de la IP de Tailscale que ya quedó habilitada en el certificado).
- Tu PC cliente conectada a la misma tailnet que `pcbox` (ya lo está, si seguiste [`pcbox/pcbox.bootstrap.md`](../pcbox/pcbox.bootstrap.md)).

Antes de cada comando de este documento, apuntá `kubectl`/`helm` al cluster:

```bash
export KUBECONFIG=~/pcbox-kubeconfig.yaml
```

## 1. Crear el OAuth client del operator

Es un OAuth client **distinto** al `TS_OAUTH_CLIENT_ID`/`TS_OAUTH_SECRET` de [`secrets-for-github-actions.crear-secretos.md`](../secrets-for-github-actions/secrets-for-github-actions.crear-secretos.md) — ese lo usa el runner de GitHub Actions para unirse a la tailnet y tiene el tag `tag:continuous-integration`; este lo usa el operator para crear nodos nuevos en la tailnet (uno por cada Ingress) y necesita su propio tag.

1. Entrá a la [consola de admin de Tailscale, página Trust credentials](https://console.tailscale.com/admin/settings/trust-credentials) con la misma cuenta.
2. Botón **Credential → OAuth**.
3. **Scopes**: marcá `write` en las tres — el operator los necesita para manejar dispositivos vía la API y para crear auth keys para sí mismo y para cada proxy que levanta:
   - **General → Services**
   - **Devices → Core**
   - **Keys → Auth Keys**
4. **Tags**: asigná `tag:k8s-operator` (tiene que coincidir con el que uses en el paso 3 al instalar el Helm chart).
5. Generá el cliente y copiá el **Client ID** y el **Client Secret** apenas se muestren — el secret solo se ve una vez.

Estos valores no se cargan en GitHub — se usan una sola vez, a mano, en el paso 3. No los commitees.

### Crear los tags necesarios

El operator necesita **dos** tags declarados en la [ACL policy](https://console.tailscale.com/admin/acls) de la tailnet — no alcanza con el que usaste arriba:

- `tag:k8s-operator`: el operator en sí. Owner: vos (tu usuario).
- `tag:k8s`: los proxies que el operator crea por cada `Ingress` (uno por app). Owner: **`tag:k8s-operator`**, no tu usuario — es lo que le permite al operator auto-asignarse este tag a los proxies que levanta.

Se crean desde **Access controls → Tags → Create tag** (o editando `tagOwners` directamente en la ACL policy, si preferís el editor JSON). Si te salteás `tag:k8s`, el operator instala bien pero después falla al crear cada proxy con `requested tags [tag:k8s] are invalid or not permitted (400)` en sus logs.

## 2. Habilitar MagicDNS y HTTPS Certificates en la tailnet

El operator necesita ambas cosas prendidas para poder darle a cada app un nombre (`<app>.tu-tailnet.ts.net`) y un certificado HTTPS válido:

1. En la [página DNS de la consola de admin](https://console.tailscale.com/admin/dns) → activá **MagicDNS** si no está activo.
2. En la misma página, activá **HTTPS Certificates**.

## 3. Instalar el Tailscale Operator

Desde tu PC cliente, con el `KUBECONFIG` ya apuntando al cluster (paso 0):

```bash
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update

helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --namespace=tailscale \
  --create-namespace \
  --set-string oauth.clientId="<TS_OAUTH_CLIENT_ID_OPERATOR>" \
  --set-string oauth.clientSecret="<TS_OAUTH_SECRET_OPERATOR>" \
  --wait
```

Reemplazá `<TS_OAUTH_CLIENT_ID_OPERATOR>` y `<TS_OAUTH_SECRET_OPERATOR>` por los valores del paso 1.

Verificar que el operator quedó arriba:

```bash
kubectl get pods -n tailscale
```

Debería haber un pod `operator-*` en estado `Running`.

## 4. Crear el `Ingress` de cada app

El Service de cada app ya existe (`ClusterIP`, puerto `3000`, namespaces `iam` y `ticket-hub`) — el `Ingress` solo le dice al operator cuál exponer y con qué nombre.

`ingress-iam.yaml`:

```yaml
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
        - iam
```

`ingress-ticket-hub.yaml`:

```yaml
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
        - ticket-hub
```

El valor en `tls.hosts` es el nombre que va a tener el nodo en la tailnet (`iam.tu-tailnet.ts.net`, `ticket-hub.tu-tailnet.ts.net`) — no hace falta que coincida con el `name` del Service, pero para no confundirse los dejamos iguales.

Aplicar ambos:

```bash
kubectl apply -f ingress-iam.yaml
kubectl apply -f ingress-ticket-hub.yaml
```

El operator crea, por cada `Ingress`, un pod proxy que se une a la tailnet como un nodo nuevo — tarda unos segundos la primera vez.

> Si aplicaste los `Ingress` **antes** de tener listos los tags del paso 1, el operator va a quedar reintentando con backoff exponencial (los reintentos se van espaciando cada vez más — segundos, después minutos). Arreglar el tag no dispara un reintento inmediato. Forzalo reiniciando el operator, que vuelve a procesar todo desde cero al arrancar:
> ```bash
> kubectl rollout restart deployment/operator -n tailscale
> ```

## 5. Verificar el acceso desde una PC cliente

Esperar a que cada `Ingress` tenga hostname asignado:

```bash
kubectl get ingress -n iam iam
kubectl get ingress -n ticket-hub ticket-hub
```

La columna `ADDRESS` debería mostrar `iam.tu-tailnet.ts.net` y `ticket-hub.tu-tailnet.ts.net` respectivamente (puede tardar un minuto en aparecer).

Desde cualquier PC cliente conectada a la misma tailnet, sin necesidad de VPN adicional ni abrir puertos:

```
https://iam.tu-tailnet.ts.net
https://ticket-hub.tu-tailnet.ts.net
```

> Si no carga: confirmá que la PC cliente esté en la misma tailnet (`tailscale status`) y que la ACL policy no esté bloqueando el tráfico hacia `tag:k8s-operator` — por defecto (sin ACLs custom) todos los nodos de la tailnet se ven entre sí.

## 6. Datos que quedan de este proceso

| Dato | Qué es | De qué paso salió | Para qué es |
|---|---|---|---|
| `TS_OAUTH_CLIENT_ID_OPERATOR` / `TS_OAUTH_SECRET_OPERATOR` | Credenciales de aplicación para que el operator cree nodos en la tailnet | Paso 1 (consola de admin de Tailscale) | Instalar/reinstalar el operator (paso 3) — no se commitea, se usa a mano |
| `iam.tu-tailnet.ts.net` | Hostname MagicDNS de `iam` | Paso 4 (`tls.hosts` del Ingress) + paso 2 (MagicDNS) | URL de acceso a `iam` desde cualquier PC cliente de la tailnet |
| `ticket-hub.tu-tailnet.ts.net` | Hostname MagicDNS de `ticket-hub` | Paso 4 (`tls.hosts` del Ingress) + paso 2 (MagicDNS) | URL de acceso a `ticket-hub` desde cualquier PC cliente de la tailnet |
