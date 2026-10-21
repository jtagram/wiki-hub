# Componentes del ecosistema

Los repositorios que forman Jtagram y la función que cumple cada uno.

| Repositorio | Qué es y qué función cumple |
|---|---|
| [iam](https://github.com/jtagram/iam) | Aplicación web donde el personal interno administra las aplicaciones, los roles y los usuarios del ecosistema. |
| [iam-api](https://github.com/jtagram/iam-api) | API que valida las credenciales y emite los tokens JWT con los que las demás aplicaciones autorizan a sus usuarios. Guarda las aplicaciones, los roles y los usuarios. |
| [ticket-hub](https://github.com/jtagram/ticket-hub) | Aplicación web donde el personal interno pide cambios de infraestructura mediante tickets y los consulta. |
| [ticket-hub-api](https://github.com/jtagram/ticket-hub-api) | API que guarda los tickets y controla quién puede aprobarlos. Al aprobar un ticket, le pide la ejecución a `infra-hub-api`. |
| [infra-hub-api](https://github.com/jtagram/infra-hub-api) | API que ejecuta los cambios sobre la infraestructura: SQL en PostgreSQL, tareas en el servidor y comandos o manifiestos en Kubernetes. |
| [database-hub-api](https://github.com/jtagram/database-hub-api) | Proyecto con las entidades y las migraciones de las bases de datos de `iam-api`, `infra-hub-api` y `ticket-hub-api`. |
| [deploy-hub-api](https://github.com/jtagram/deploy-hub-api) | Workflows de GitHub Actions y manifiestos de Kubernetes que construyen, publican y despliegan cada aplicación en `local`, `dev` y `prod`. Es el único con acceso al cluster. |
| [wiki-hub](https://github.com/jtagram/wiki-hub) | Esta documentación: cómo montar el ecosistema y cómo funciona. |

<p align="right"><a href="../README.md">← Back</a></p>
