# direktor_appv2

Aplicacion movil de Direktor construida en Flutter. Este proyecto se esta desarrollando por iteraciones, tomando como base los wireframes funcionales, la estructura del proyecto definida para Flutter y el modelo SQLite de la aplicacion movil.

## Objetivo

Construir una app movil corporativa para Direktor que permita gestionar proyectos, analisis de restricciones y actas de reuniones, con una interfaz moderna, formal y alineada a la identidad visual de la marca.

## Alcance actual

El proyecto ya no esta solo en etapa visual. Actualmente incluye:

- Splash, login y hub de proyectos.
- Vista de proyectos con resumen de restricciones, reuniones y sincronizacion operativa.
- Lista de restricciones con filtros, cambio de estado, detalle y formulario.
- Reuniones y seguimiento de acuerdos.
- Persistencia local en SQLite con cola `sync_queue`, `sync_log` y `app_settings`.
- Flujo `push/pull` preparado para integracion backend.
- Autenticacion remota preparada con persistencia local de `auth_user` y `auth_session`.
- Contrato OpenAPI y ejemplos de integracion para Swagger/mock backend.
- Integracion visual del logo real de Direktor en la app y en el splash nativo de Android.
- veremos


## Stack

- Flutter
- Dart
- SQLite como base de datos local operativa
- HTTP client nativo para integracion con APIs
- Android resources para splash y branding nativo

## Estructura relevante

- `lib/app/`: arranque de aplicacion, router y tema.
- `lib/features/`: modulos funcionales por dominio.
- `lib/shared/`: widgets y utilidades reutilizables.
- `assets/db/`: esquema SQLite de referencia.
- `assets/Iimages/`: recursos graficos usados por la app.
- `lib/data/local/`: inicializacion y mantenimiento de SQLite.
- `lib/data/remote/`: clientes HTTP de autenticacion y sincronizacion.
- `docs/`: contrato backend, OpenAPI y ejemplos `full`/`operational`.
- `android/app/src/main/res/`: splash y recursos nativos Android.

## Estado del desarrollo

La linea visual principal ya fue ajustada a la identidad de Direktor usando azul corporativo y acentos naranja. La app tambien tiene arquitectura offline-first funcional:

- login local y remoto preparado
- cola de cambios local
- `push` hacia `sync/inbox`
- `pull` `full` y `operational`
- mapeo y `upsert` hacia SQLite local

La integracion backend aun depende de que el servicio real responda con el contrato definido en `docs/openapi_sync.yaml` y `docs/backend_sync_contract.md`.

## Flujo de trabajo

Las entregas se estan separando por ramas de iteracion para mantener control de avances y validacion progresiva.

- `codex/iteracion1`: base visual inicial y ajustes de frontend.
- `codex/iteracion2`: siguiente fase de trabajo a partir de la base aprobada.
- `codex/iteracion5`: sync offline-first, auth remota preparada, OpenAPI y contrato backend.
