# jtagram

Sistema de gestión de entorno de desarrollo de software con procesos definidos.

## Cómo empezar

### Opción 1: montar jtagram desde cero

Prepara el servidor `pcbox`, las 3 VMs (`local`, `dev` y `prod`), MicroK8s, los secretos, los repositorios, los workflows de GitHub Actions y el primer deploy de las 5 apps.

Sigue la guía paso a paso: [set-up-the-ecosystem-jtagram.md](set-up-the-ecosystem-jtagram.md).

## Checklist

- Debe resolver un problema real

  Sistema de gestión de entorno de desarrollo de software con procesos definidos.

  **Problemas principales**

  1. **Velocidad de desarrollo con IA.** Cada acción que se hace en la gestión del entorno queda registrada. Cuando se va a desarrollar una feature, un MCP puede verificar qué gestiones ya están hechas y qué falta para esa feature.
  2. **Romper la dependencia de empleados.** Todo lo que hace un empleado sigue procesos definidos y documentados, y queda registrado. Cuando se va, deja su conocimiento ordenado para que la siguiente persona continúe sin perder tiempo verificando qué se hizo ni cómo está hecho. Quien llega puede hacerle preguntas a la IA y comprobar que la respuesta es verdadera, sin frustración.

  **Beneficios secundarios**

  3. **Documentación actualizada por procesos automáticos.** Por ejemplo, cada jueves un automatismo crea un PR para actualizar la documentación.
  4. **Prolijidad de trabajo.** La metodología de procesos definidos indica cómo trabajar de forma ordenada.
- Debe gestionar autenticación

  La autenticación está centralizada en `iam-api`. Hay dos tipos de usuario:

  - **Usuarios internos** (email y contraseña): personas que inician sesión desde las aplicaciones.
  - **Usuarios de aplicación** (`clienteId` y `clienteSecret`): cuentas de servicio que usan las aplicaciones para comunicarse entre sí.

  Ambos se autentican contra `iam-api` y reciben un JWT. Ese JWT se envía en las siguientes requests como `Authorization: Bearer <token>`.
- Debe gestionar autorización, accesos y roles
- Debe implementar reglas de negocio
- Debe tener persistencia de datos
- Debe tener validaciones
- Debe tener manejo de errores
- Debe tener una API REST
- Debe tener documentación de la API
- Debe tener tests unitarios
- Debe tener tests de integración
- Debe tener tests end-to-end
- Debe tener código limpio y ordenado
- Debe aplicar principios SOLID
- Debe aplicar patrones de diseño cuando corresponda
- Debe tener una arquitectura bien definida
- Debe tener separación de responsabilidades
- Debe manejar configuración por ambientes
- Debe utilizar variables de entorno
- Debe tener logging
- Debe tener manejo de excepciones centralizado
- Debe tener paginación, filtros y ordenamiento
- Debe manejar transacciones
- Debe contemplar concurrencia cuando corresponda
- Debe tener seguridad de la API
- Debe proteger información sensible
- Debe tener rate limiting
- Debe tener versionado de API
- Debe tener documentación técnica
- Debe tener README completo
- Debe tener Docker
- Debe tener Docker Compose para desarrollo local
- Debe tener CI/CD
- Debe tener análisis estático/linting
- Debe tener formateo automático
- Debe tener control de calidad del código
- Debe tener migraciones de base de datos
- Debe tener seeders/datos iniciales
- Debe contemplar auditoría de operaciones importantes
- Debe tener health checks
- Debe tener observabilidad
- Debe tener métricas
- Debe contemplar seguridad y buenas prácticas OWASP
- Debe manejar archivos si el dominio lo requiere
- Debe manejar procesos asíncronos si el dominio lo requiere
- Debe utilizar colas/mensajería si tiene sentido
- Debe contemplar caché si tiene sentido
- Debe contemplar idempotencia cuando corresponda
- Debe manejar reintentos y fallos de servicios externos
- Debe integrar al menos algún servicio externo
- Debe tener arquitectura preparada para escalar
- Debe contemplar disponibilidad y recuperación ante fallos
- Debe tener infraestructura como código si el alcance lo permite
- Debe estar desplegado en un entorno real
- Debe tener documentación de arquitectura
- Debe tener diagramas de arquitectura
- Debe tener decisiones técnicas documentadas (ADR)
- Debe tener estrategia de branching y Git
- Debe tener commits claros y convencionales
- Debe demostrar capacidad de refactorización
- Debe demostrar decisiones técnicas justificadas
- Debe tener casos de uso claramente definidos
- Debe tener criterios de aceptación
- Debe tener manejo de escenarios exitosos y fallidos
- Debe tener datos de prueba realistas
- Debe tener una estrategia de backups y recuperación
- Debe tener monitoreo de errores
- Debe tener seguridad en las dependencias
- Debe tener gestión de secretos
- Debe demostrar conocimientos de arquitectura y diseño de sistemas
- Debe demostrar capacidad de evolucionar el sistema sin romper funcionalidades existentes
