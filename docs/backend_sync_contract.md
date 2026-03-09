# Direktor Mobile Sync Contract

## Endpoints

### `POST /sync/inbox`
Recibe la cola local del movil para que el backend la deje en `sync_inbox`.

Request:
```json
{
  "userId": 7,
  "source": "direktor_appv2",
  "items": [
    {
      "queueId": 15,
      "entityType": "restriction",
      "entityId": "405",
      "operationType": "update",
      "payload": "{\"codAnaResActividad\":405,\"codEstadoActividad\":\"completed\"}"
    }
  ]
}
```

Response minima:
```json
{
  "success": true,
  "accepted": 1,
  "processedAt": "2026-03-09T11:00:00-05:00",
  "results": [
    {
      "queueId": 15,
      "status": "accepted"
    }
  ]
}
```

### `POST /sync/pull`
Devuelve cambios remotos para actualizar SQLite local.

Request:
```json
{
  "userId": 7,
  "source": "direktor_appv2",
  "scope": "full",
  "businessDate": "2026-03-09",
  "since": "2026-03-09T08:30:00-05:00"
}
```

Campos:
- `scope = full`: descarga total
- `scope = operational`: solo datos operativos
- `businessDate`: dia operativo Peru, con corte a las 06:00
- `since`: ultima sync exitosa del cliente para incremental operativo

## Respuesta de `pull`

```json
{
  "success": true,
  "scope": "full",
  "serverTime": "2026-03-09T11:00:00-05:00",
  "businessDate": "2026-03-09",
  "version": "2026-03-09T11:00:00-05:00",
  "catalogs": {
    "areas": [],
    "analysisAreas": [],
    "fronts": [],
    "phases": [],
    "types": [],
    "statuses": [],
    "members": []
  },
  "projects": [],
  "restrictions": [],
  "meetings": [],
  "participants": [],
  "agreements": [],
  "comments": []
}
```

## Reglas por scope

### `scope = full`
Debe devolver:
- `catalogs.areas`
- `catalogs.analysisAreas` opcional
- `catalogs.fronts`
- `catalogs.phases`
- `catalogs.types`
- `catalogs.statuses`
- `catalogs.members`
- `projects`
- `restrictions`
- `meetings`
- `participants`
- `agreements`
- `comments`

### `scope = operational`
Debe devolver:
- `restrictions`
- `meetings`
- `participants`
- `agreements`
- `comments`

Puede devolver `projects` si quieres refresco ligero de metadatos, pero no es obligatorio.

## Forma esperada de cada arreglo

Cada registro debe llegar con:
- clave primaria real
- `updated_at`
- `deleted`
- todos los campos necesarios para `upsert`

### `projects`
```json
{
  "codProyecto": 101,
  "desNombreProyecto": "Proyecto A",
  "codEstado": 1,
  "codEmpresa": 1,
  "desEmpresa": "Direktor",
  "codTipoProyecto": 1,
  "desTipoProyecto": "Edificacion",
  "codMoneda": 1,
  "desMoneda": "Soles",
  "desSimboloMoneda": "S/",
  "codUbigeo": 150101,
  "desUbigeo": "Lima",
  "desDireccion": "Av. Primavera 123",
  "dayFechaInicio": "2026-01-10",
  "is_last_selected": 0,
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.areas` -> `projects_area_member`
```json
{
  "codArea": 1,
  "desArea": "Supervision",
  "cod_Empresa": 1,
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.analysisAreas` -> `anares_area`
```json
{
  "codAnaresArea": 1,
  "codProyecto": 101,
  "codArea": 1,
  "desArea": "Supervision",
  "bgColor": "#0A66B7",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.fronts` -> `anares_front`
```json
{
  "codAnaResFrente": 201,
  "codProyecto": 101,
  "codAnaRes": 1,
  "desAnaResFrente": "Torre A",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.phases` -> `anares_phase`
```json
{
  "codAnaResFase": 301,
  "codAnaResFrente": 201,
  "codProyecto": 101,
  "codAnaRes": 1,
  "desAnaResFase": "Estructuras",
  "bgColor": "#0A66B7",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.types` -> `anares_type`
```json
{
  "codTipoRestriccion": 1,
  "desTipoRestriccion": "Permisos",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.statuses` -> `anares_status`
```json
{
  "codEstado": "pending",
  "desEstado": "Pendiente",
  "iconColor": "#98A3B3",
  "codModulo": 1,
  "codElementoControl": 1,
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `catalogs.members` -> `projects_member`
```json
{
  "codProyIntegrante": 1001,
  "codProyecto": 101,
  "user_id": 7,
  "codArea": 1,
  "desArea": "Supervision",
  "codRolIntegrante": 1,
  "desRolIntegrante": "Supervisor de obra",
  "codEstadoInvitacion": "OK",
  "desCorreo": "diego@direktor.pe",
  "numCelular": "999999999",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `restrictions` -> `anares_restriction`
```json
{
  "codAnaResActividad": 405,
  "codProyecto": 101,
  "codAnaRes": 1,
  "codAnaResFrente": 201,
  "codAnaResFase": 301,
  "desFrente": "Torre A",
  "desFase": "Estructuras",
  "desActividad": "Falta permiso municipal",
  "desRestriccion": "Se requiere aprobacion municipal",
  "codTipoRestriccion": 1,
  "desTipoRestriccion": "Permisos",
  "dayFechaRequerida": "2026-03-12",
  "dayFechaConciliada": null,
  "dayFechaLevantamiento": null,
  "idUsuarioResponsable": 7,
  "desResponsable": "Juan Perez",
  "codEstadoActividad": "pending",
  "desEstadoActividad": "Pendiente",
  "colorEstado": "#98A3B3",
  "codArea": "1",
  "codUsuarioSolicitante": "7",
  "desSolicitante": "Diego Warthon",
  "is_completed": 0,
  "is_overdue": 0,
  "is_due_today": 0,
  "is_pending": 1,
  "is_in_progress": 0,
  "priority_order": 3,
  "dayFechaCreacion": "2026-03-09T08:00:00-05:00",
  "dayFechaModificacion": "2026-03-09T10:30:00-05:00",
  "updated_at": "2026-03-09T10:30:00-05:00",
  "deleted": false
}
```

### `meetings` -> `meetings_meeting`
```json
{
  "codActReuReuniones": 501,
  "codProyecto": 101,
  "codActReu": 1,
  "codActReuCategoria": 1,
  "codActReuSubCategoria": 10,
  "desCategoria": "Produccion",
  "desSubCategoria": "Semanal",
  "desNombre": "Reunion semanal de obra",
  "dayFechaReunion": "2026-03-12",
  "dayFechaCierre": "2026-03-12",
  "horHoraInicio": "08:00",
  "horHoraFin": "09:00",
  "codEstado": "scheduled",
  "desEstado": "Programada",
  "desLinkActaReunion": "",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `participants` -> `meetings_participant`
```json
{
  "codActReuParticipante": 701,
  "codActReuSubCategoria": 10,
  "codProyecto": 101,
  "idUsuarioParticipante": 7,
  "codProyIntegrante": 1001,
  "desNombre": "Diego Warthon",
  "desCorreoElectronico": "diego@direktor.pe",
  "codArea": "1",
  "flgParticipanteInvitado": 0,
  "codEstado": 1,
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `agreements` -> `meetings_agreement`
```json
{
  "codActReuAcuerdos": 601,
  "codActReuReuniones": 501,
  "codProyecto": 101,
  "desAcuerdo": "Enviar planos actualizados",
  "dayFechaAcuerdo": "2026-03-11",
  "dayFechaAplazo": null,
  "dayFechaLevantamiento": null,
  "numAplazos": 0,
  "idUsuarioResponsable": 9,
  "desResponsable": "Maria Torres",
  "codEstado": "pending",
  "desEstado": "Pendiente",
  "codGrupoAcuerdo": 1,
  "desGrupoAcuerdo": "Pendiente",
  "desColorGrupoAcuerdo": "#F0A11E",
  "is_overdue": 0,
  "is_pending": 1,
  "is_completed": 0,
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

### `comments` -> `meetings_comment`
```json
{
  "codComentario": 801,
  "codActReuAcuerdos": 601,
  "codComentarioPadre": null,
  "idUsuario": 7,
  "desMensaje": "Se coordino con arquitectura.",
  "dayFechaComentario": "2026-03-09T11:00:00-05:00",
  "updated_at": "2026-03-09T11:00:00-05:00",
  "deleted": false
}
```

## Estrategia de borrado

La app espera `deleted: true` por registro.

Comportamiento:
- si `deleted = false`: `upsert`
- si `deleted = true`: delete fisico local

No hace falta mandar listas separadas de eliminados si se mantiene esta bandera.

## Estrategia de conflicto

Regla actual implementada en movil:
- `projects`, `areas`, `fronts`, `phases`, `types`, `statuses`, `members`, `participants`, `comments`: gana servidor
- `restrictions` y `agreements`: si el registro tiene cambio local en `sync_queue` con estado `pending` o `failed`, el movil conserva el dato local y omite el registro remoto

Cuando eso pasa:
- el pull no pisa el local
- se registra un `pull_conflict` en `sync_log`

Esto equivale a:
- `push first`
- luego `pull`
- y si aun queda una cola pendiente, `local pending wins`

## Notas para backend

- Enviar siempre filas completas, no parciales
- Mantener nombres de columnas iguales a SQLite cuando sea posible
- Incluir `updated_at` en todas las entidades
- Incluir `deleted` en todas las entidades
- Para `scope = operational`, devolver solo cambios desde `since`
- Para `scope = full`, devolver dataset completo vigente
