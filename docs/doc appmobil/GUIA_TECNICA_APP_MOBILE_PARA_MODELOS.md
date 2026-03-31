# GUIA TECNICA APP MOBILE DIREKTOR (PARA OTROS MODELOS/AGENTES)

## 1) Proposito de esta guia
Este documento explica la app mobile `direktor_appv2` con foco en:
- arquitectura
- estructura SQLite
- reglas de negocio por modulo
- vistas y navegacion
- sincronizacion offline-first
- convenciones criticas para que otro modelo continue sin romper flujos

Objetivo: que un agente nuevo pueda entrar al proyecto y operar con contexto real, sin asumir comportamiento incorrecto.

---

## 2) Mapa rapido del proyecto

Raiz principal:
- `lib/app`: bootstrap app, tema, router, estado global
- `lib/data`: repositorio, sqlite, clientes remotos
- `lib/features`: modulos funcionales
- `assets/db/direktor_mobile_v2.sql`: modelo base SQLite
- `docs/`: contratos backend y ejemplos

Archivos de referencia clave:
- `lib/app/router.dart`
- `lib/app/routes/route_names.dart`
- `lib/app/state/app_controller.dart`
- `lib/data/app_repository.dart`
- `lib/data/local/app_database.dart`
- `lib/data/remote/sync_api_client.dart`
- `assets/db/direktor_mobile_v2.sql`

---

## 3) Arquitectura funcional

### 3.1 Capas
- UI: `features/**/presentation/screens/*.dart`
- Estado/app service: `AppController` (Inheritable por `AppScope`)
- Dominio + persistencia + sync: `AppRepository`
- Persistencia local: `sqflite` via `AppDatabase`
- Integracion remota:
  - auth: `auth_api_client.dart`
  - sync push/pull: `sync_api_client.dart`

### 3.2 Patron operativo
- UI llama `AppScope.of(context).metodoX(...)`
- `AppController` ejecuta guardado en `_runGuarded`
- `AppRepository` persiste en SQLite
- `AppRepository` encola evento en `sync_queue`
- `AppController` dispara push inmediato en operaciones criticas
- loops de fondo reintentan push/pull

---

## 4) Navegacion y vistas

Rutas (`route_names.dart`):
- `/` splash
- `/login`
- `/projects`
- `/profile`
- `/restrictions`, `/restrictions/completed`, `/restrictions/detail`, `/restrictions/create`, `/restrictions/edit`
- `/control-hitos`, `/control-hitos/detail`, `/control-hitos/create`, `/control-hitos/edit`, `/control-hitos/documents`, `/control-hitos/extensions`, `/control-hitos/extensions/create`
- `/acta-reuniones`

Pantallas por modulo:
- Auth:
  - `features/auth/presentation/screens/login_screen.dart`
- Hub proyectos:
  - `features/projects/presentation/screens/projects_hub_screen.dart`
  - `features/projects/presentation/screens/profile_screen.dart`
- Analisis de restricciones:
  - `restrictions_list_screen.dart`
  - `restriction_detail_screen.dart`
  - `restriction_form_screen.dart`
  - `completed_restrictions_screen.dart`
- Control de hitos:
  - `control_hitos_screen.dart`
  - `hito_detail_screen.dart`
  - `hito_form_screen.dart`
  - `hito_extensions_screen.dart`
  - `hito_extension_form_screen.dart`
  - `hito_documents_screen.dart`
- Acta de reuniones (Option9):
  - `o9_hub_screen.dart`
  - `o9_category_screen.dart`
  - `o9_subcategory_screen.dart`
  - `o9_session_screen.dart`
  - `o9_overdue_screen.dart`
  - `o9_agreement_detail_screen.dart`
  - `o9_comments_screen.dart`

---

## 5) Modelo SQLite (inventario completo)

Fuente de verdad local: `assets/db/direktor_mobile_v2.sql`

### 5.1 Auth y proyectos
- `auth_session`
- `auth_user`
- `projects_project`
- `projects_member`
- `projects_area_member`

### 5.2 Analisis de restricciones (anares)
- Catalogos:
  - `anares_analysis`
  - `anares_front`
  - `anares_phase`
  - `anares_type`
  - `anares_area`
  - `anares_status`
- Operativo:
  - `anares_restriction`
  - `anares_summary`

### 5.3 Acta de reuniones (actreu)
- Estructura:
  - `actreu_actareuniones`
  - `actreu_categoria`
  - `actreu_subcategoria`
  - `actreu_reuniones`
- Participantes y maestros:
  - `actreu_participantes`
  - `actreu_integrantes`
  - `actreu_grupoacuerdo`
- Acuerdos:
  - `actreu_acuerdos`
  - `actreu_acuerdosfoto`
  - `actreu_comentarios_acuerdo`
  - `actreu_asistencias`
  - `actreu_summary`
- Tablas de estado:
  - `actreu_status_categoria`
  - `actreu_status_subcategoria`
  - `actreu_status_reuniones`
  - `actreu_status_acuerdos`

### 5.4 Control de hitos (conhit / conthit)
- Maestros:
  - `conhit_tipohito`
  - `conhit_tipoclasificacion`
  - `conhit_statusinterno`
  - `conhit_statuscontractual`
- Operativo:
  - `conhit_controlhitos`
  - `conhit_general`
  - `conhit_detallehitos`
  - `conhit_documentos`
  - `conhit_archivosfechareal`
  - `conhit_integrantes`
  - `conthit_detallehitosamp`

### 5.5 Infra de sync
- `sync_queue`
- `sync_log`
- `app_settings`

---

## 6) Relaciones de negocio clave

### 6.1 Restricciones
- `anares_restriction.codAnaResFrente` -> `anares_front`
- `anares_restriction.codAnaResFase` -> `anares_phase`
- `anares_restriction.codTipoRestriccion` -> `anares_type`
- resumen por proyecto en `anares_summary`

### 6.2 Control de hitos
- `conhit_general` depende de `conhit_controlhitos`
- `conhit_detallehitos` depende de `conhit_general` y `conhit_controlhitos`
- ampliaciones en `conthit_detallehitosamp`
- soporte documental en `conhit_documentos` y `conhit_archivosfechareal`

### 6.3 Acta de reuniones
- `actreu_categoria` cuelga de `actreu_actareuniones`
- `actreu_subcategoria` cuelga de `actreu_categoria`
- `actreu_reuniones` cuelga de `actreu_subcategoria`
- `actreu_participantes` cuelga de `actreu_subcategoria`
- `actreu_acuerdos` cuelga de `actreu_reuniones`
- `actreu_comentarios_acuerdo` cuelga de `actreu_acuerdos`
- `actreu_asistencias` cuelga de `actreu_reuniones` y referencia participante
- snapshot de cierre en `actreu_acuerdosfoto`

---

## 7) Sincronizacion offline-first

### 7.1 Principio general
Toda accion de negocio:
1. se guarda primero en SQLite
2. se encola en `sync_queue` (pending)
3. push remoto intenta enviar
4. si falla, queda `failed` y reintenta
5. al sincronizar, estado cambia a `synced`

### 7.2 Push
Cliente: `sync_api_client.dart -> pushInbox()`
- endpoint por defecto:
  - `DIREKTOR_PUSH_INBOX_URL`
  - default: `http://31.220.20.226/api/mobile/sync/inbox`
- `HttpClient.connectionTimeout = 10s`

Implementacion de cola (`app_repository.dart`):
- `_enqueueSync(...)`:
  - agrega geolocalizacion al payload
  - mergea eventos por entidad si ya existe pendiente/fallido
  - regla importante: `create + delete` antes de sincronizar => no-op (se elimina de cola)
- `_pushQueue(...)`:
  - procesa por item (evita que 1 fallo bloquee todo el lote)
  - logs en `sync_log`

### 7.3 Pull
Cliente: `sync_api_client.dart -> pullData()`
- endpoint por defecto:
  - `DIREKTOR_API_BASE_URL/sync/pull`
  - default base: `https://desaapi.direktor.com.pe/api/mobile`
- `HttpClient.connectionTimeout = 10s`

Flujos:
- Full sync
- Operational sync (incremental)

### 7.4 Loops automaticos (`AppController`)
- push loop cada 30s
- operational loop cada 1 min (con regla de ventana horaria y ultimo sync)
- al volver conectividad: refresca y corre chequeos automaticos

### 7.5 Flags y metadatos de payload
- `isNew = 1` en creates
- `isFromRemoteTable` para linaje remoto/local
- `geolocation` se adjunta a payload sync

---

## 8) Reglas de negocio por modulo (resumen operativo)

## 8.1 Analisis de restricciones
- calculo de banderas derivadas:
  - `is_completed`, `is_overdue`, `is_due_today`, `is_pending`, `is_in_progress`
- prioridad visual por estado/atraso
- summary por proyecto en `anares_summary`

## 8.2 Control de hitos
- datos generales editables (`conhit_general`)
- detalle por hito (`conhit_detallehitos`)
- ampliaciones en `conthit_detallehitosamp`
- documentos asociados y carga de soporte
- estados contractual/interno desde tablas maestras

## 8.3 Acta de reuniones
- jerarquia: categoria -> subcategoria -> sesion -> acuerdos
- no se inicia sesion sin participantes configurados
- asistentes se guardan al marcar (no esperar cierre)
- acuerdos se guardan en caliente (create/update/status/defer)
- cierre de acta:
  - cierra sesion
  - snapshot a `actreu_acuerdosfoto`
- acuerdos informativos (`codEstado = 6`):
  - no llevan seguimiento normal
- aplazos:
  - `dayFechaAplazo` + incremento `numAplazos`
  - para analitica, fecha efectiva = `dayFechaAplazo` si existe, sino `dayFechaAcuerdo`
- estados expuestos al usuario:
  - en UI se simplifica a `en progreso` y `finalizado`
  - estados 2/4/5 se calculan internamente (aplazado/atrasado)

Reglas de eliminacion (actreu):
- categoria: solo si no tiene subcategorias activas
- subcategoria: solo si no tiene sesiones/acuerdos activos
- sesion: solo si no fue iniciada (sin asistencia/acuerdos)
- participante: solo si no esta asignado a acuerdos
- acuerdo (sesion):
  - eliminable solo si pertenece a la sesion actual
  - acuerdos historicos (otras sesiones) no se eliminan desde sesion vigente

---

## 9) Flujo E2E por caso

### 9.1 Login
1. auth remoto
2. guarda `auth_user` y `auth_session`
3. bootstrap local
4. full sync inicial

### 9.2 Cambio operativo (ejemplo asistencia)
1. usuario marca asistencia en UI
2. `AppController.upsertActreuAttendance(...)`
3. `AppRepository.upsertActreuAttendance(...)` guarda en `actreu_asistencias`
4. `_enqueueSync(entityType=actreu_asistencia, operation=upsert)`
5. push inmediato + loops de respaldo

### 9.3 Cambio operativo (ejemplo acuerdo)
1. create/update/defer/status en sesion
2. guarda en `actreu_acuerdos`
3. encola `actreu_acuerdo`
4. push inmediato

---

## 10) Convenciones de IDs y consistencia

- IDs locales nuevos suelen generarse con metodos `_next...Id()` en `AppRepository`
- para entidades locales nuevas, payload lleva `isNew`
- mantener consistencia FK local (orden de insercion y checks de existencia)
- en pull, para evitar romper offline local:
  - se usa `_hasPendingQueueItem(...)`
  - se evita sobreescribir filas locales con cambios pendientes

---

## 11) Riesgos tecnicos frecuentes

- FK errors por orden de aplicacion en pull
- eventos en cola bloqueados por payload invalido (mitigado al procesar por item)
- errores de encoding en textos UI (mojibake)
- desbordes UI por textos largos en chips/dropdowns
- inconsistencias por no recargar vista tras acciones locales

---

## 12) Checklist para otro modelo antes de tocar codigo

1. Leer `app_repository.dart` y ubicar metodo real del caso
2. Validar tabla SQLite involucrada en `direktor_mobile_v2.sql`
3. Verificar si la accion requiere encolado sync
4. Confirmar reglas de negocio del modulo (no asumir CRUD puro)
5. Probar:
   - online
   - offline
   - reconexion
6. Revisar `sync_log` y `sync_queue` tras prueba

---

## 13) Archivos de contrato backend y ejemplos

- `docs/backend_sync_contract.md`
- `docs/openapi_sync.yaml`
- `docs/sync_pull_full_example.json`
- `docs/sync_pull_operational_example.json`
- `docs/laravel_sync_examples/*`

Uso recomendado:
- `sync_pull_full_example.json`: referencia de bootstrap completo (`catalogs + projects + anares + conthit + actreu`).
- `sync_pull_operational_example.json`: referencia incremental operativa (cambios recientes por modulo).
- Ambos ejemplos ya estan alineados al contrato actual y listos para backend/testing.

---

## 14) Nota de trabajo para agentes futuros

- No asumir que una pantalla usa data dummy: revisar carga desde `AppController` y `AppRepository`.
- En actreu, las reglas de sesiones, participantes y acuerdos tienen restricciones funcionales fuertes.
- Siempre que una accion cambie datos de negocio, validar:
  - persistencia sqlite
  - encolado sync
  - comportamiento offline
  - refresco de UI
