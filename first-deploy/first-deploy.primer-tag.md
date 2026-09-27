# Primer tag: en git y en Docker Hub

`release-<app>.yml` pide `previous_stable_tag` (tiene que **existir ya**, en git y en Docker Hub) y `new_tag` (tiene que **no existir todavía**). En el primer release de cada app no hay ningún release anterior real, así que hay que crear ese primer tag a mano antes de disparar el workflow — si no, el job `validate` falla.

Por cada uno de los 5 repos (`iam`, `iam-api`, `infra-hub-api`, `ticket-hub`, `ticket-hub-api`):

```bash
cd <app>
git tag v0.1.0
git push origin v0.1.0

docker build -t <DOCKERHUB_USERNAME>/<app>:v0.1.0 .
docker login
docker push <DOCKERHUB_USERNAME>/<app>:v0.1.0
```

Al disparar el workflow por primera vez, usá `previous_stable_tag: v0.1.0` (el que acabás de crear) y un `new_tag` distinto para la versión real que vas a publicar (por ejemplo `v0.1.1`).
