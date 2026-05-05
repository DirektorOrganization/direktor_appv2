# Bitacora de Cambios - 2026-05-05 (Avance Grafico, 2 commits + working tree)

## Alcance
- Bitacora generada tomando como tramo de referencia los 2 commits mas recientes del autor `cariasdirektor`:
  - `71e5ade` - `Cambios en diseño y UX para la configuracion inicial de la fase 3`
  - `80bc59c` - `Agregar eventos y corregir diferencias del modulo avance grafico con la app web (Fase 1 , 2 y 3)`
- Se agrega ademas el estado actual del `working tree` todavia no commiteado.
- Se excluyen deliberadamente los archivos de referencia web/backend en `docs/avancegraficoweb/`.

---

## Archivos Flutter/Dart considerados en el estado actual
- `lib/app/state/app_controller.dart`
- `lib/data/app_repository.dart`
- `lib/data/app_repository_apply.dart`
- `lib/data/app_repository_sync.dart`
- `lib/data/local/app_database.dart`
- `lib/data/models/app_models.dart`
- `lib/data/remote/auth_api_client.dart`
- `lib/data/remote/sync_api_client.dart`
- `lib/features/graphic_progress/presentation/screens/avance_grafico_campo_screen.dart`

Resumen del `working tree` actual:
- 9 archivos tracked modificados.
- Aproximadamente `1515` inserciones y `1044` eliminaciones en diff actual.

---

## Resumen funcional consolidado

### 1. Generacion y encolado de eventos en Avance Grafico
- Se reforzo la logica de generacion de eventos `create`, `update` y `delete` para las 3 fases del modulo.
- Se centralizo el control desde `AppController` con timers y flush diferido para evitar ruido de sincronizacion cuando el usuario hace varios cambios seguidos.
- Se hizo mas granular el encolado por entidad afectada, en lugar de depender de guardados mas amplios o ambiguos.

### 2. Fase 1
- Ajustes de configuracion de forma, sentido y niveles globales con flujo mas estable en movil.
- Refuerzo de numeracion y renumeracion de posiciones para acercarla a la logica de la web.
- Mejoras en altas/bajas logicas y reutilizacion de secciones por lado.
- Encolado mas preciso de eventos para secciones y posiciones afectadas.
- Correcciones visuales recientes en `CAMPO`:
  - numeracion de posiciones segun orden de secciones
  - sentido horario/antihorario reflejado en la vista
  - ajuste de matriz lateral izquierda para antihorario
  - eliminacion de cabeceras visuales celestes que no correspondian

### 3. Fase 2
- Persistencia y control de configuracion de pisos uniformes.
- Mejora del flujo de actualizacion de cuadros y su emision de eventos de sincronizacion.
- Refuerzo de la resolucion de contexto activo (fase/proyecto/modulo) al generar cambios.

### 4. Fase 3
- Se consolido la configuracion inicial tipo wizard para pisos, sectores globales y actividades globales.
- Se robustecio el CRUD local/global de:
  - pisos
  - sectores
  - actividades
  - pivotes por piso
  - celdas `actividad x sector x piso`
- Se reforzo la generacion de eventos de sincronizacion para celdas y pivotes de Fase 3.
- Se mantuvo el enfoque de trabajo por piso despues de la inicializacion global.
- Correccion reciente importante:
  - la autocreacion de `avagra_fasetres` ahora registra `codUsuarioCreacion`, `dayFechaCreacion`, `codUsuarioModificacion` y `dayFechaModificacion`, alineado con las otras fases

### 5. Integracion en sync pull / aplicacion local
- Se incorporaron cambios para integrar mejor el modulo Avance Grafico dentro del flujo de `pull` / `sync`.
- La presencia de cambios en `app_repository_apply.dart`, `app_repository_sync.dart` y `app_repository.dart` indica integracion del modulo en la aplicacion de payloads remotos y su reconstruccion local.
- Esto incluye soporte para entidades y estructuras nuevas/ajustadas de Avance Grafico dentro del ciclo offline-first.

### 6. Base de datos local y modelos
- Se ajustaron estructuras SQLite necesarias para soportar los nuevos flujos del modulo.
- Se agregaron o reforzaron columnas y migraciones usadas por Avance Grafico.
- Se ampliaron modelos para reflejar mejor los datos de Fase 1, 2 y 3, especialmente en conteos, configuracion e inicializacion.

### 7. Correcciones menores y de entorno
- Se hicieron correcciones puntuales para alinear comportamiento movil con la web sin rehacer el modulo completo.

## Lectura ejecutiva
- El bloque de trabajo de este tramo estuvo enfocado en cerrar diferencias entre movil y web para Avance Grafico.
- El eje principal fue:
  - mejorar emision de eventos sync en Fase 1, 2 y 3
  - corregir logicas puntuales de numeracion y comportamiento visual
  - reforzar inicializacion y persistencia de Fase 3
  - integrar mejor el modulo dentro del flujo de `pull` / `sync`
