# AGENTS.md — direktor_appv2

## Project

Flutter mobile app for Direktor (corporate project management). Offline-first with SQLite local DB and prepared backend sync.

## Commands

```
flutter run              # Run on connected device/emulator
flutter analyze          # Lint/static analysis (no custom rules beyond flutter_lints)
flutter test             # Run tests (only widget_test.dart exists)
fvm flutter <cmd>        # Use if FVM is installed; .fvmrc sets stable
flutter build apk --debug  # Build debug APK
flutter clean && flutter pub get  # Clean rebuild (required after pubspec changes)
```

**Android Kotlin incremental is DISABLED** in `android/gradle.properties`. If you re-enable it, expect `Daemon compilation failed` on Windows when PUB_CACHE and project are on different drives.

No typecheck, formatter, or CI pipeline configured.

## Architecture

- **Entry point**: `lib/main.dart` — initializes intl, notifications, background sync, then runs `DirektorApp`
- **Routing**: `lib/app/router.dart` — manual `MaterialPageRoute` switch on route names (not go_router or auto_route). Route names in `lib/app/routes/route_names.dart`
- **State**: `AppController` (ChangeNotifier) via `AppScope.of(context)`. All UI calls go through `AppScope.of(context).metodoX(...)`
- **Feature modules** (`lib/features/`): `auth`, `projects`, `analysis_restrictions`, `control_hitos`, `meetings`, `insights`, `shell`
- **Data layer** (`lib/data/`):
  - `app_repository.dart` — main orchestrator, public API
  - `app_repository_sync.dart` — push/pull sync logic
  - `app_repository_insights.dart` — insight recalculation per module
  - `app_repository_actreu_read.dart` — Acta Reuniones read queries
  - `app_repository_actreu_ops.dart` — Acta Reuniones business ops (create/update/delete/session/agreement/comments)
  - `app_repository_apply.dart` — `_apply*` mappers for pull payload -> SQLite
  - `app_repository_utils.dart` — date parsing, IDs, common helpers
  - `local/app_database.dart` — sqflite SQLite initialization
  - `remote/` — `auth_api_client.dart`, `sync_api_client.dart`
- **Sync rules**: `lib/app/sync/sync_rules.dart` — constants for sync intervals, windows, and behavior
- **Insight rules**: `lib/app/insights/insight_rules.dart` — constants for insight generation
- **Shared** (`lib/shared/widgets/`): reusable widgets

## Key quirks

- **Many experimental hub variants**: `HubModeloA` through `HubModeloV` in `lib/features/projects/presentation/screens/` — redesign experiments. `HubDefaultScreen` is the production entry.
- **Control de Hitos**: `Hv7Screen` is the official version (matriz operativa + Gantt). Older v2/v3/v5/v6 versions moved to `_deprecated/`.
- **Offline-first sync**: local `sync_queue` + `sync_log` tables, push to `sync/inbox`, pull full/operational. Backend integration depends on contract in `docs/doc appmobil/`.
- **Assets**: `assets/db/direktor_mobile_v2.sql` (schema reference), `assets/Iimages/isotipoD.png` (logo).
- **Branches**: iteration branches follow `codex/iteracionN` pattern.

## Sync behavior

- **Push loop**: every 5s, processes pending/failed queue items one-by-one
- **Operational pull check**: every 1 min, but actual min interval is 3 min between pulls
- **Sync window**: 07:00-19:00 (Lima) for automatic syncs
- **Daily full sync**: allowed from 06:00
- **On reconnect**: pushes pending queue + operational pull immediately
- **Endpoints**: push -> `http://31.220.20.226/api/mobile/sync/inbox`, pull -> `https://desaapi.direktor.com.pe/api/mobile/sync/pull`
- **Timeout**: 10s connection timeout on both push and pull
- **Queue merge**: `create + delete` before sync = no-op (row removed from queue)
- **Payload flags**: `isNew=1` for creates, `isFromRemoteTable` for lineage, `geolocation` attached

## Business rules to know

- **Acta de reuniones**: hierarchy is categoria -> subcategoria -> sesion -> acuerdos. No session start without participants. Attendance saved on mark (not at close). Session close snapshots to `actreu_acuerdosfoto`. Informativos (`codEstado=6`) have no normal tracking. Deferrals: `dayFechaAplazo` + increment `numAplazos`, effective date = aplazo if exists, else `dayFechaAcuerdo`.
- **Deletion rules (actreu)**: categoria only if no active subcategorias; subcategoria only if no active sessions/agreements; session only if not started; participant only if not assigned to agreements; agreement only if from current session.
- **Insights**: recalculated on full sync. Only shown when unresolved `warning` or `critical` alerts exist. Manual resolution via `setModuleInsightResolved(...)`. Rules in `lib/app/insights/insight_rules.dart`.
- **Restricciones**: derived flags (`is_completed`, `is_overdue`, `is_due_today`, `is_pending`, `is_in_progress`). Summary per project in `anares_summary`.

## SQLite tables (summary)

Source of truth: `assets/db/direktor_mobile_v2.sql`

- Auth/projects: `auth_session`, `auth_user`, `projects_project`, `projects_member`, `projects_area_member`
- Restricciones: `anares_analysis`, `anares_front`, `anares_phase`, `anares_type`, `anares_area`, `anares_status`, `anares_restriction`, `anares_summary`
- Acta reuniones: `actreu_actareuniones`, `actreu_categoria`, `actreu_subcategoria`, `actreu_reuniones`, `actreu_participantes`, `actreu_integrantes`, `actreu_grupoacuerdo`, `actreu_acuerdos`, `actreu_acuerdosfoto`, `actreu_comentarios_acuerdo`, `actreu_asistencias`, `actreu_summary`, `actreu_status_*`
- Control hitos: `conhit_tipohito`, `conhit_tipoclasificacion`, `conhit_statusinterno`, `conhit_statuscontractual`, `conhit_controlhitos`, `conhit_general`, `conhit_detallehitos`, `conhit_documentos`, `conhit_archivosfechareal`, `conhit_integrantes`, `conthit_detallehitosamp`
- Sync infra: `sync_queue`, `sync_log`, `app_settings`

## Testing

Only `test/widget_test.dart` exists — a single smoke test that pumps the app and checks for "DIREKTOR" text. No unit tests, no integration tests. Run with `flutter test`.

## Docs

- `docs/doc appmobil/GUIA_TECNICA_APP_MOBILE_PARA_MODELOS.md` — comprehensive technical guide (Spanish)
- `docs/doc appmobil/DIREKTOR_APPV2_DOCUMENTACION_TECNICA_CONFLUENCE.md` — Confluence-style architecture doc
- `docs/doc appmobil/openapi_sync.yaml` — OpenAPI contract
- `docs/doc appmobil/sync_pull_full_example.json` — full sync payload reference
- `docs/doc appmobil/sync_pull_operational_example.json` — operational sync payload reference
- `docs/doc appmobil/resumen cambios/` — session change logs

## Checklist before touching code

1. Find the method in `AppController` and `AppRepository`
2. Confirm the SQLite table involved in `direktor_mobile_v2.sql`
3. Verify if the action requires sync enqueue
4. Confirm module business rules (not pure CRUD)
5. Test: online, offline, reconnection
6. Review `sync_log` and `sync_queue` after testing
