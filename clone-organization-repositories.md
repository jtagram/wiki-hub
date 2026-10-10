# Clonar los repositorios de la organización jtagram

Copia los 7 repositorios de la organización [`jtagram`](https://github.com/orgs/jtagram/repositories) a tu propia organización de GitHub, solo con la rama principal y `dev`.

## 1. Crear tu organización

1. Entra a [github.com/account/organizations/new](https://github.com/account/organizations/new).
2. Elige el plan (Free alcanza para repositorios públicos).
3. Define el nombre: será `NUEVA_ORG` más abajo.

## 2. Repositorios

| Repositorio | Rama principal |
|---|---|
| [`wiki-hub`](https://github.com/jtagram/wiki-hub) | `master` |
| [`iam`](https://github.com/jtagram/iam) | `main` |
| [`iam-api`](https://github.com/jtagram/iam-api) | `master` |
| [`ticket-hub`](https://github.com/jtagram/ticket-hub) | `main` |
| [`ticket-hub-api`](https://github.com/jtagram/ticket-hub-api) | `master` |
| [`infra-hub-api`](https://github.com/jtagram/infra-hub-api) | `master` |
| [`deploy-hub-api`](https://github.com/jtagram/deploy-hub-api) | `master` |

## 3. Clonar un repositorio

### 3.1. Clonar solo la rama principal y `dev`

```bash
REPO=<nombre-del-repo>
RAMA_PRINCIPAL=<main-o-master>

git clone --single-branch --branch "$RAMA_PRINCIPAL" "https://github.com/jtagram/$REPO.git"
cd "$REPO"
git fetch origin dev:dev
```

### 3.2. Crear el repositorio vacío en tu organización

Con el mismo nombre que el original y sin README, licencia ni `.gitignore`.

Desde la web: **New repository** en tu organización. O con la CLI:

```bash
gh repo create "<NUEVA_ORG>/$REPO" --public
```

### 3.3. Cambiar el remoto y subir las ramas

```bash
NUEVA_ORG=<tu-organizacion>

git remote set-url origin "https://github.com/$NUEVA_ORG/$REPO.git"
git push -u origin "$RAMA_PRINCIPAL"
git push -u origin dev
```

Repite 3.1 a 3.3 para cada uno de los 7 repositorios.

## 4. Verificar

En cada repositorio clonado:

```bash
git remote -v
git branch -a
```

Salida esperada (ejemplo con `iam-api`):

```
origin  https://github.com/<NUEVA_ORG>/iam-api.git (fetch)
origin  https://github.com/<NUEVA_ORG>/iam-api.git (push)
  dev
* master
  remotes/origin/dev
  remotes/origin/master
```

- `origin` apunta a tu organización, no a `jtagram`.
- Solo existen la rama principal y `dev`.
