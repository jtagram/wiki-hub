# Crear el primer tag en GitHub y Docker Hub

`release-<app>.yml` pide `previous_stable_tag` (debe **existir ya**, en git y en Docker Hub) y `new_tag` (debe **no existir todavía**). En el primer release no hay un tag anterior real, así que se crea a mano antes de disparar el workflow. Si no, el job `validate` falla.

Se hace una vez por app y por ambiente.

## 1. Datos

| Ambiente | Rama | Tag |
|---|---|---|
| Local | `local` | `local-v0.1.0` |
| Desarrollo | `dev` | `dev-v0.1.0` |
| Producción | la principal del repo | `prod-v0.1.0` |

El prefijo evita que los tags de distintos ambientes choquen: un tag de git y una imagen de Docker Hub son únicos por repositorio.

| Repositorio | Rama de producción |
|---|---|
| `iam` | `main` |
| `iam-api` | `master` |
| `infra-hub-api` | `master` |
| `ticket-hub` | `main` |
| `ticket-hub-api` | `master` |

## 2. Preparar

Abre una terminal en la carpeta que contiene los 5 repositorios (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub` y `ticket-hub-api`). Reemplaza `<tu-usuario-de-dockerhub>` y pega:

```bash
DOCKERHUB_USERNAME=<tu-usuario-de-dockerhub>
docker login
```

Ejecuta todos los bloques siguientes en la misma terminal y siempre desde esa carpeta: cada bloque entra al repo con `cd` y vuelve con `cd ..`.

## 3. Crear los tags

Cada bloque crea el tag en git sobre la última versión de la rama, construye la imagen desde esa misma rama y la sube a Docker Hub.

### Local

#### iam

```bash
cd iam
git fetch origin
git checkout local
git pull origin local
git tag local-v0.1.0
git push origin local-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam:local-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam:local-v0.1.0"
cd ..
```

#### iam-api

```bash
cd iam-api
git fetch origin
git checkout local
git pull origin local
git tag local-v0.1.0
git push origin local-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam-api:local-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam-api:local-v0.1.0"
cd ..
```

#### infra-hub-api

```bash
cd infra-hub-api
git fetch origin
git checkout local
git pull origin local
git tag local-v0.1.0
git push origin local-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/infra-hub-api:local-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/infra-hub-api:local-v0.1.0"
cd ..
```

#### ticket-hub

```bash
cd ticket-hub
git fetch origin
git checkout local
git pull origin local
git tag local-v0.1.0
git push origin local-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub:local-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub:local-v0.1.0"
cd ..
```

#### ticket-hub-api

```bash
cd ticket-hub-api
git fetch origin
git checkout local
git pull origin local
git tag local-v0.1.0
git push origin local-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub-api:local-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub-api:local-v0.1.0"
cd ..
```

### Desarrollo

#### iam

```bash
cd iam
git fetch origin
git checkout dev
git pull origin dev
git tag dev-v0.1.0
git push origin dev-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam:dev-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam:dev-v0.1.0"
cd ..
```

#### iam-api

```bash
cd iam-api
git fetch origin
git checkout dev
git pull origin dev
git tag dev-v0.1.0
git push origin dev-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam-api:dev-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam-api:dev-v0.1.0"
cd ..
```

#### infra-hub-api

```bash
cd infra-hub-api
git fetch origin
git checkout dev
git pull origin dev
git tag dev-v0.1.0
git push origin dev-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/infra-hub-api:dev-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/infra-hub-api:dev-v0.1.0"
cd ..
```

#### ticket-hub

```bash
cd ticket-hub
git fetch origin
git checkout dev
git pull origin dev
git tag dev-v0.1.0
git push origin dev-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub:dev-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub:dev-v0.1.0"
cd ..
```

#### ticket-hub-api

```bash
cd ticket-hub-api
git fetch origin
git checkout dev
git pull origin dev
git tag dev-v0.1.0
git push origin dev-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub-api:dev-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub-api:dev-v0.1.0"
cd ..
```

### Producción

#### iam

```bash
cd iam
git fetch origin
git checkout main
git pull origin main
git tag prod-v0.1.0
git push origin prod-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam:prod-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam:prod-v0.1.0"
cd ..
```

#### iam-api

```bash
cd iam-api
git fetch origin
git checkout master
git pull origin master
git tag prod-v0.1.0
git push origin prod-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/iam-api:prod-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/iam-api:prod-v0.1.0"
cd ..
```

#### infra-hub-api

```bash
cd infra-hub-api
git fetch origin
git checkout master
git pull origin master
git tag prod-v0.1.0
git push origin prod-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/infra-hub-api:prod-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/infra-hub-api:prod-v0.1.0"
cd ..
```

#### ticket-hub

```bash
cd ticket-hub
git fetch origin
git checkout main
git pull origin main
git tag prod-v0.1.0
git push origin prod-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub:prod-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub:prod-v0.1.0"
cd ..
```

#### ticket-hub-api

```bash
cd ticket-hub-api
git fetch origin
git checkout master
git pull origin master
git tag prod-v0.1.0
git push origin prod-v0.1.0
docker build -t "$DOCKERHUB_USERNAME/ticket-hub-api:prod-v0.1.0" .
docker push "$DOCKERHUB_USERNAME/ticket-hub-api:prod-v0.1.0"
cd ..
```

## 4. Verificar

### GitHub

Cada repo debe listar los 3 tags (`dev-v0.1.0`, `local-v0.1.0` y `prod-v0.1.0`). Los hashes varían:

```bash

git -C iam ls-remote --tags origin

git -C iam-api ls-remote --tags origin

git -C infra-hub-api ls-remote --tags origin

git -C ticket-hub ls-remote --tags origin

git -C ticket-hub-api ls-remote --tags origin

```

Para confirmar que un tag apunta a la rama correcta, compara con el commit de la rama. Ejemplo con `iam-api` y `dev`:

```bash
git -C iam-api rev-parse dev-v0.1.0^{commit} origin/dev
```

Las dos líneas deben mostrar el mismo hash.

### Docker Hub

```bash

docker manifest inspect "$DOCKERHUB_USERNAME/iam:local-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/iam:dev-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/iam:prod-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/iam-api:local-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/iam-api:dev-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/iam-api:prod-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/infra-hub-api:local-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/infra-hub-api:dev-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/infra-hub-api:prod-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub:local-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub:dev-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub:prod-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub-api:local-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub-api:dev-v0.1.0" > /dev/null && echo OK

docker manifest inspect "$DOCKERHUB_USERNAME/ticket-hub-api:prod-v0.1.0" > /dev/null && echo OK

```

Debe imprimir `OK` 15 veces (5 apps × 3 tags). Si algún tag no existe, aparece `no such manifest`. También puedes revisarlo en la web: `https://hub.docker.com/r/<DOCKERHUB_USERNAME>/<app>/tags`.

## 5. Usar los tags en el primer release

Al disparar el workflow por primera vez, usa como `previous_stable_tag` el tag que acabas de crear para ese ambiente y un `new_tag` distinto del mismo ambiente:

| Ambiente | `previous_stable_tag` | `new_tag` |
|---|---|---|
| Local | `local-v0.1.0` | `local-v0.1.1` |
| Desarrollo | `dev-v0.1.0` | `dev-v0.1.1` |
| Producción | `prod-v0.1.0` | `prod-v0.1.1` |
