# Clonar la organización jtagram a tu propia cuenta

Instructivo para llevarte los 7 repositorios de la organización [`jtagram`](https://github.com/orgs/jtagram/repositories) (pública) a tu propia organización de GitHub, quedándote solo con la rama principal y `dev` de cada uno (sin arrastrar otras ramas que puedan existir).

## 1. Crear una organización en GitHub

1. Entrá a [github.com/account/organizations/new](https://github.com/account/organizations/new).
2. Elegí el plan (Free alcanza para repositorios públicos).
3. Elegí un nombre para la organización — es el que vas a usar más abajo como `NUEVA_ORG`.
4. Completá los datos que pida (email de contacto, si es personal o de una empresa) y confirmá la creación.
5. (Opcional) Invitá a otros miembros desde **Settings → People** si vas a trabajar en equipo.

Con la organización creada, todavía no tiene repositorios — se van a ir creando uno por uno en el paso 3, a medida que clones cada uno de `jtagram`.

## 2. Repositorios de la organización jtagram

| Repositorio | Qué es | Rama principal | Rama `dev` |
|---|---|---|---|
| [`wiki-hub`](https://github.com/jtagram/wiki-hub) | Documentación de todo el sistema (este mismo repo) | `master` | sí |
| [`iam`](https://github.com/jtagram/iam) | Frontend Next.js del identity provider | `main` | sí |
| [`iam-api`](https://github.com/jtagram/iam-api) | Backend NestJS del identity provider (firma y valida los JWT de todo el sistema) | `master` | sí |
| [`ticket-hub`](https://github.com/jtagram/ticket-hub) | Frontend Next.js de la herramienta de tickets de infraestructura | `main` | sí |
| [`ticket-hub-api`](https://github.com/jtagram/ticket-hub-api) | Backend NestJS de la herramienta de tickets | `master` | sí |
| [`infra-hub-api`](https://github.com/jtagram/infra-hub-api) | Backend NestJS que ejecuta los playbooks de Ansible contra el servidor `pcbox` | `dev` (ver nota abajo) | sí (es la rama activa) |
| [`deploy-hub-api`](https://github.com/jtagram/deploy-hub-api) | Workflows de GitHub Actions y manifiestos de Kubernetes para deployar todo | `master` | sí |


## 3. Clonar cada repositorio y apuntarlo a tu nueva organización

La idea para cada uno de los 7 repos es la misma: clonar solo la rama principal (evitando traer de arrepente todas las demás ramas que pueda tener el repo), traer además la rama `dev`, y después cambiar el remoto `origin` para que apunte a tu propia organización en vez de a `jtagram`.

### 3.1. Clonar solo la rama principal y `dev`

Reemplazá `REPO` y `RAMA_PRINCIPAL` según la tabla de arriba (por ejemplo, para `iam-api`: `REPO=iam-api`, `RAMA_PRINCIPAL=master`; para `iam`: `REPO=iam`, `RAMA_PRINCIPAL=main`):

```bash
REPO=<nombre-del-repo>
RAMA_PRINCIPAL=<main-o-master>

git clone --single-branch --branch "$RAMA_PRINCIPAL" "https://github.com/jtagram/$REPO.git"
cd "$REPO"
git fetch origin dev:dev
```

`--single-branch --branch "$RAMA_PRINCIPAL"` hace que el clone inicial solo traiga esa rama (no las demás que pueda tener el repo). El `git fetch origin dev:dev` de después trae puntualmente la rama `dev`, creándola en tu copia local. Terminado esto, tu clon local tiene exactamente 2 ramas: la principal y `dev` — nada más.


### 3.2. Crear el repositorio vacío en tu organización

Antes de poder pushear, el repositorio tiene que existir (vacío) del lado de tu nueva organización. Dos formas:

**Desde la web**: en tu organización, botón **New repository**, mismo nombre que el repo original (`$REPO`), sin inicializarlo con README/licencia/`.gitignore` (para no generar un commit que choque con el historial que estás por traer).

**Con la CLI de GitHub** (`gh`), si la tenés instalada y autenticada:

```bash
gh repo create "<NUEVA_ORG>/$REPO" --public --description "Réplica de jtagram/$REPO"
```

(usá `--private` en vez de `--public` si preferís que no sea público).

### 3.3. Cambiar el remoto y pushear

```bash
NUEVA_ORG=<tu-organizacion>

git remote set-url origin "https://github.com/$NUEVA_ORG/$REPO.git"
git push -u origin "$RAMA_PRINCIPAL"
git push -u origin dev
```

### 3.4. Repetir para los 7 repositorios

Repetí los pasos 3.1 a 3.3 para cada uno: `wiki-hub`, `iam`, `iam-api`, `ticket-hub`, `ticket-hub-api`, `infra-hub-api`, `deploy-hub-api`. Al terminar, tu organización va a tener los 7 repositorios, cada uno con su rama principal y `dev`, con el remoto `origin` apuntando a tu cuenta en vez de a `jtagram`.

## 4. Verificar

En cada repo clonado:

```bash
git remote -v
git branch -a
```

`remote -v` tiene que mostrar tu organización (no `jtagram`) tanto en `fetch` como en `push`, y `branch -a` tiene que mostrar únicamente la rama principal y `dev` (más sus correspondientes `remotes/origin/...`) — ninguna otra rama del repo original.
