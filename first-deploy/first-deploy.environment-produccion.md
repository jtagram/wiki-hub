# Environment `production`: el botón de aprobación

El job `approve-and-deploy` de `release-<app>.yml` frena en `environment: production` y pide aprobación manual antes de disparar el deploy. Ese botón solo aparece si el Environment tiene una regla de protección configurada — sin ella, GitHub crea el Environment solo (la primera vez que se usa) sin ninguna regla, y el job pasa derecho sin pedir nada.

Por cada uno de los 5 repos de app (los Environments no se comparten entre repos):

1. `<app>` → **Settings** → **Environments** → **New environment** → nombre exacto `production`.
2. **Deployment protection rules** → **Required reviewers** → agregate → **Save protection rules**.

Si no te aparece "Required reviewers": en el plan Free de GitHub esa opción solo existe para repos públicos (o para cualquier repo si la organización es Team/Enterprise) — hacé el repo público (**Settings** → **Danger Zone** → **Change visibility**) o subí el plan de la organización.
