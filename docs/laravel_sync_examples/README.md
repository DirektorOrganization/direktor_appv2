# Laravel Sync Inbox Examples

Este directorio contiene una propuesta base para implementar la recepcion de cambios del app movil hacia `sync_inbox` usando Laravel.

Archivos incluidos:
- `sync_inbox_table.sql`: definicion SQL de la tabla `sync_inbox`
- `routes_api.php`: ejemplo de ruta API
- `SyncInboxController.php`: controlador base
- `SyncInboxRequest.php`: validacion del request
- `SyncInboxService.php`: servicio para guardar items en inbox
- `SyncInbox.php`: modelo Eloquent

Notas:
- Esto es una base inicial, pensada para adaptarse al backend web de Direktor.
- La logica de procesamiento hacia tablas finales quedaria en otro servicio/job aparte.
