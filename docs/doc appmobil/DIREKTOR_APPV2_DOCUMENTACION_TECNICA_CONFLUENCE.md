# DIREKTOR APP V2 - DOCUMENTACION TECNICA (CONFLUENCE)

## 1. Objetivo
Este documento describe la arquitectura tecnica real de `direktor_appv2` para continuidad de desarrollo por equipos y por modelos/agentes.

Cobertura:
- arquitectura y responsabilidades por capa
- base de datos SQLite
- flujos de negocio por modulo
- sincronizacion offline-first
- rutas/pantallas
- reglas criticas (eliminaciones, estados, cierre de sesion, aplazos)

Documento maestro complementario:
- `docs/doc appmobil/GUIA_TECNICA_APP_MOBILE_PARA_MODELOS.md`

---

## 2. Arquitectura general

Estructura:
- `lib/app`
  - arranque, router, tema, estado global (`AppController`, `AppScope`)
- `lib/data`
  - `app_repository.dart` (orquestador principal)
  - `app_repository_sync.dart` (sync/pull/push)
  - `app_repository_insights.dart` (motor de insights)
  - `app_repository_utils.dart` (helpers reutilizables)
  - `app_repository_actreu_read.dart` (lecturas Acta Reuniones)
  - `app_repository_actreu_ops.dart` (operaciones Acta Reuniones)
  - `app_repository_apply.dart` (aplicadores `_apply*` de payload pull)
  - `local/app_database.dart` (apertura/mantenimiento DB)
  - `remote/auth_api_client.dart`, `remote/sync_api_client.dart`
- `lib/app/sync/sync_rules.dart` (constantes de sync)
- `lib/app/insights/insight_rules.dart` (constantes de insights)
- `lib/features`
  - modulos por dominio
- `assets/db/direktor_mobile_v2.sql`
  - schema base local

Patron:
1. UI llama `AppScope.of(context).metodo(...)`
2. `AppController` orquesta y protege (`_runGuarded`)
3. `AppRepository` persiste en SQLite y encola sync si aplica
4. push remoto intenta envio
5. pull remoto refresca catalogos/datos operativos

---

## 3. Modulos y vistas

### 3.1 Auth
- `login_screen.dart`

### 3.2 Hub proyectos
- `projects_hub_screen.dart`
- `profile_screen.dart`

### 3.3 Analisis de restricciones
- `restrictions_list_screen.dart`
- `restriction_detail_screen.dart`
- `restriction_form_screen.dart`
- `completed_restrictions_screen.dart`

### 3.4 Control de hitos
- `control_hitos_screen.dart`
- `hito_detail_screen.dart`
- `hito_form_screen.dart`
- `hito_extensions_screen.dart`
- `hito_extension_form_screen.dart`
- `hito_documents_screen.dart`

### 3.5 Acta de reuniones (Option 9)
- `o9_hub_screen.dart`
- `o9_category_screen.dart`
- `o9_subcategory_screen.dart`
- `o9_session_screen.dart`
- `o9_overdue_screen.dart`
- `o9_agreement_detail_screen.dart`
- `o9_comments_screen.dart`

---

## 4. Rutas

Definidas en:
- `lib/app/routes/route_names.dart`
- `lib/app/router.dart`

Principales:
- `/`, `/login`, `/projects`, `/profile`
- `/restrictions` y subrutas
- `/control-hitos` y subrutas
- `/acta-reuniones`

---

## 5. Modelo SQLite (inventario)

Fuente:
- `assets/db/direktor_mobile_v2.sql`

### 5.1 Auth y proyectos
- `auth_session`
- `auth_user`
- `projects_project`
- `projects_member`
- `projects_area_member`

### 5.2 Restricciones (anares)
- catalogos:
  - `anares_analysis`, `anares_front`, `anares_phase`, `anares_type`, `anares_area`, `anares_status`
- operativas:
  - `anares_restriction`, `anares_summary`

### 5.3 Acta de reuniones (actreu)
- estructura:
  - `actreu_actareuniones`, `actreu_categoria`, `actreu_subcategoria`, `actreu_reuniones`
- participantes/maestros:
  - `actreu_participantes`, `actreu_integrantes`, `actreu_grupoacuerdo`
- acuerdos:
  - `actreu_acuerdos`, `actreu_acuerdosfoto`, `actreu_comentarios_acuerdo`, `actreu_asistencias`
- resumen/estados:
  - `actreu_summary`
  - `actreu_status_categoria`, `actreu_status_subcategoria`, `actreu_status_reuniones`, `actreu_status_acuerdos`

### 5.4 Control de hitos
- maestros:
  - `conhit_tipohito`, `conhit_tipoclasificacion`, `conhit_statusinterno`, `conhit_statuscontractual`
- operativas:
  - `conhit_controlhitos`, `conhit_general`, `conhit_detallehitos`, `conhit_documentos`, `conhit_archivosfechareal`, `conhit_integrantes`, `conthit_detallehitosamp`

### 5.5 Infra sync
- `sync_queue`
- `sync_log`
- `app_settings`

---

## 6. Sincronizacion offline-first

### 6.1 Principio
Toda mutacion de negocio:
1. se guarda en SQLite
2. se encola en `sync_queue`
3. se intenta push remoto
4. si falla, queda para reintento automatico

### 6.2 Endpoints
- Pull:
  - `POST {DIREKTOR_API_BASE_URL}/sync/pull`
  - default base: `https://desaapi.direktor.com.pe/api/mobile`
- Push:
  - `POST {DIREKTOR_PUSH_INBOX_URL}`
  - default: `http://31.220.20.226/api/mobile/sync/inbox`

Cliente:
- `lib/data/remote/sync_api_client.dart`

### 6.3 Timeouts y loops
- `HttpClient.connectionTimeout = 10s` (push y pull)
- loops de `AppController` controlados por `SyncRules`:
  - push loop: cada 30s
  - operational check loop: cada 1 min
  - `operationalMinInterval`: 30 min (cadencia real minima)
  - ventana horaria auto: 06:00 a 19:00 (Lima)
  - full diario auto: habilitado desde las 06:00

### 6.4 Cola
`_enqueueSync(...)` en `app_repository.dart`:
- agrega `geolocation` a payload
- agrega `isNew=1` en create
- usa `isFromRemoteTable` para linaje
- merge de eventos por entidad
- regla:
  - create + delete antes de sincronizar => no-op (borra fila de cola)

`_pushQueue(...)`:
- envia item por item (si uno falla, los demas pueden seguir)

---

## 7. Reglas de negocio criticas

## 7.1 Restricciones
- recalculo de flags derivados:
  - `is_completed`, `is_overdue`, `is_due_today`, `is_pending`, `is_in_progress`
- resumen por proyecto en `anares_summary`

## 7.2 Control de hitos
- cabecera general editable
- detalle de hito editable con estados contractual/interno
- ampliaciones y documentos con persistencia local y sync

## 7.3 Acta de reuniones
- jerarquia:
  - categoria -> subcategoria -> sesion -> acuerdos
- no se inicia sesion sin participantes
- asistencia y acuerdos persisten en caliente (no esperar cierre)
- al cerrar sesion:
  - cierre logico
  - snapshot en `actreu_acuerdosfoto`
- informativos (`codEstado=6`):
  - no se gestionan como seguimiento normal
- aplazos:
  - guardan `dayFechaAplazo`
  - incrementan `numAplazos`
  - fecha efectiva analitica = aplazo si existe, sino fecha acuerdo

## 7.4 Insights
Reglas y mensajes centralizados:
- `lib/app/insights/insight_rules.dart`

Motor de calculo/persistencia:
- `lib/data/app_repository_insights.dart`
- salida persistida en tabla `module_insights`

Cobertura:
- analisis de restricciones
- acta de reuniones

Comportamiento:
- recalculo en sync full
- se muestran insights solo cuando hay alertas/criticos no resueltos
- resolucion manual por item desde UI (flag `resolved`)

---

## 8. Reglas de eliminacion (actreu)

- Categoria:
  - eliminable si no tiene subcategorias activas
- Subcategoria:
  - eliminable si no tiene sesiones/acuerdos activos
- Sesion:
  - eliminable solo si no fue iniciada (sin asistencia/acuerdos)
- Participante:
  - eliminable solo si no esta asignado a acuerdos
- Acuerdo desde sesion:
  - eliminable solo si pertenece a la sesion actual
  - acuerdos de sesiones anteriores no se eliminan desde sesion vigente

---

## 9. Flujo E2E de referencia

### 9.1 Login
1. auth remoto
2. persistencia `auth_user` y `auth_session`
3. bootstrap
4. full sync

### 9.2 Asistencia en sesion
1. UI marca asistencia
2. `upsertActreuAttendance(...)`
3. guarda `actreu_asistencias`
4. encola `actreu_asistencia`
5. push inmediato + reintento en loops

### 9.3 Acuerdo en sesion
1. create/update/defer/status
2. guarda `actreu_acuerdos`
3. encola `actreu_acuerdo`
4. push inmediato

---

## 10. Archivos de contrato backend

- `docs/doc appmobil/openapi_sync.yaml`
- `docs/doc appmobil/sync_pull_full_example.json`
- `docs/doc appmobil/sync_pull_operational_example.json`
- `docs/doc appmobil/GUIA_TECNICA_APP_MOBILE_PARA_MODELOS.md`

---

## 11. Checklist para mantenimiento por otro modelo/agente

1. ubicar metodo en `AppController` y `AppRepository`
2. confirmar tabla SQLite involucrada
3. validar enqueue en `sync_queue`
4. probar online + offline + reconexion
5. revisar `sync_log` y `sync_queue`
6. confirmar refresh visual en pantalla origen

