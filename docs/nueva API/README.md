# Nueva API de archivos mobile

Esta API sirve para subir archivos reales desde la app mobile antes de encolar el evento normal de negocio.

Flujo recomendado:

1. La app selecciona un archivo.
2. La app llama a `POST /api/mobile/upload-file` con `multipart/form-data`.
3. Laravel guarda el archivo en storage.
4. Laravel responde con la metadata final:
   - `fileToken`
   - `fileName`
   - `filePath`
   - `fileUrl`
   - `mimeType`
   - `size`
5. La app usa esa respuesta dentro de la cola:
   - `milestone_document:create`
   - `milestone_extension:create`

Notas:

- Esto evita mandar binarios por la cola de sync.
- El endpoint acepta PDF, Word e imagenes.
- El ejemplo deja una tabla opcional de auditoria para trazabilidad.

Archivos incluidos:

- `routes_api_upload.php`
- `MobileUploadRequest.php`
- `MobileUploadController.php`
- `mobile_uploaded_files_table.sql`

Ejemplo de uso desde mobile:

```http
POST /api/mobile/upload-file
Content-Type: multipart/form-data
```

Campos:

- `userId`
- `companyId`
- `module`
- `entityType`
- `entityId`
- `file`

Ejemplo de respuesta:

```json
{
  "success": true,
  "message": "Archivo cargado correctamente.",
  "data": {
    "fileToken": "mob_19_20260320_104530_a1b2c3d4",
    "originalName": "sustento_ampliacion.pdf",
    "fileName": "mob_19_20260320_104530_a1b2c3d4.pdf",
    "filePath": "mobile_uploads/1/control_hitos/milestone_extension/2026/03/20/mob_19_20260320_104530_a1b2c3d4.pdf",
    "fileUrl": "https://tu-dominio/storage/mobile_uploads/1/control_hitos/milestone_extension/2026/03/20/mob_19_20260320_104530_a1b2c3d4.pdf",
    "mimeType": "application/pdf",
    "extension": "pdf",
    "size": 283441,
    "module": "control_hitos",
    "entityType": "milestone_extension",
    "entityId": "1234",
    "uploadedAt": "2026-03-20T10:45:30-05:00"
  }
}
```

Luego la app puede enviar en la cola algo como:

```json
{
  "supportDocument": {
    "fileToken": "mob_19_20260320_104530_a1b2c3d4",
    "fileName": "mob_19_20260320_104530_a1b2c3d4.pdf",
    "filePath": "mobile_uploads/1/control_hitos/milestone_extension/2026/03/20/mob_19_20260320_104530_a1b2c3d4.pdf",
    "fileUrl": "https://tu-dominio/storage/mobile_uploads/1/control_hitos/milestone_extension/2026/03/20/mob_19_20260320_104530_a1b2c3d4.pdf",
    "originalName": "sustento_ampliacion.pdf",
    "mimeType": "application/pdf",
    "size": 283441
  }
}
```
