# Control de Hitos (V5/V6/V7) - Resumen técnico detallado

Fecha: 2026-04-08  
Rama: `chore/prep-next-changes-2026-04-08`

## 0. Objetivo funcional implementado

Se realizaron cambios de UI/UX y estructura para los modelos de Control de Hitos:

- `V5`: primera vista por defecto = `Timeline`.
- `V6`: primera vista por defecto = `Matriz`.
- `V7` (nuevo): primera vista por defecto = `Matriz tipo tabla (estilo HV2)`, segunda vista = `Datos`.

Adicionalmente, se estandarizó:

- nombre de “Gantt” -> **“Diagrama de hitos”**,
- botón de alta de hito con patrón visual de Restricciones (FAB pequeño, solo icono, esquina inferior derecha),
- buscador en header superior derecho (misma altura de back), con patrón de activación tipo Restricciones.

---

## 1. Rutas y navegación agregadas

### 1.1 Nuevas constantes de ruta

Archivo:
- `lib/app/routes/route_names.dart`

Cambio:
- Se añadió:
  - `static const controlHitosV7 = '/control-hitos-v7';`

### 1.2 Registro en router

Archivo:
- `lib/app/router.dart`

Cambio:
- Import:
  - `option_v7/hv7_screen.dart`
- Nuevo case en `onGenerateRoute`:
  - `case RouteNames.controlHitosV7: return const Hv7Screen();`

### 1.3 Entrada desde Hub principal

Archivo:
- `lib/features/projects/presentation/screens/hub_default_screen.dart`

Cambio:
- Se añadió un nuevo módulo:
  - título: `Hitos · Matriz V7`
  - subtítulo: `Matriz operativa + Datos + Diagrama`
  - `onTap -> RouteNames.controlHitosV7`

---

## 2. Cambios técnicos por modelo

## 2.1 V5 (`hv5_screen.dart`)

Archivo:
- `lib/features/control_hitos/presentation/screens/option_v5/hv5_screen.dart`

### 2.1.1 Estado y control

Se incorporó/ajustó:

- `TabController(length: 2, initialIndex: 0)` (Timeline default).
- `TextEditingController _searchCtrl`.
- flags:
  - `_showGantt`
  - `_showSearch`
  - `_generalEnabled`
  - `_showGeneralSummary`

### 2.1.2 Filtro de búsqueda

En `build` se filtran hitos por query:

- campos de búsqueda:
  - `code`
  - `description`
  - `typeLabel`
  - `classificationLabel`

### 2.1.3 Integración de `conhit_general`

Se agregó manejo del bloque general:

- fallback local de `MilestoneGeneralRecord` cuando `controller.milestoneGeneral == null`.
- bottom sheet de configuración:
  - habilitar/deshabilitar edición general.
- bottom sheet de edición:
  - `startDate`, `totalDays`, `totalAmount`.
- persistencia vía:
  - `controller.saveMilestoneGeneral(MilestoneGeneralDraft(...))`

Widgets agregados:

- `_TopControlsBar`
- `_GeneralSummaryCard`

### 2.1.4 Tabs y orden de vistas

Se dejó:

1. `Timeline`
2. `Datos`

### 2.1.5 Diagrama de hitos

Se actualizó panel y painter:

- etiqueta visible: `DIAGRAMA DE HITOS`.
- `_GanttPainter`:
  - líneas verticales por mes,
  - etiqueta de mes (`Ene`, `Feb`, ...),
  - texto corto de descripción por nodo,
  - `shouldRepaint => true`.

### 2.1.6 Buscador en header (patrón Restricciones)

Se removió buscador de barra interna y se implementó:

- `AppBar.actions`:
  - botón `search/search_off` con `AnimatedSwitcher`.
- `bottomSheet` condicional:
  - `_SearchBar` con `TextField` autofocus.

### 2.1.7 FAB

Se reemplazó botón ancho por:

- `FloatingActionButton.small`
- solo icono `Icons.add_rounded`
- esquina inferior derecha (default)
- deshabilitado cuando `_showSearch == true`

---

## 2.2 V6 (`hv6_screen.dart`)

Archivo:
- `lib/features/control_hitos/presentation/screens/option_v6/hv6_screen.dart`

### 2.2.1 Estado y control

Se mantuvo mismo patrón estructural que V5:

- `_showGantt`, `_showSearch`, `_generalEnabled`, `_showGeneralSummary`.
- `_searchCtrl`, `TabController(initialIndex: 0)`.

### 2.2.2 Orden de tabs

Se dejó:

1. `Matriz` (por defecto)
2. `Datos`

### 2.2.3 Integración `conhit_general`

Mismo flujo que V5:

- toggle de habilitación,
- resumen visual,
- edición y guardado (`saveMilestoneGeneral`).

### 2.2.4 Diagrama de hitos

Mejoras aplicadas:

- renombre textual a `DIAGRAMA DE HITOS`.
- métricas rápidas en panel:
  - hito activo,
  - días de avance,
  - días restantes.
- `_GanttPainter` alineado a V5:
  - marcas mensuales,
  - texto de descripción,
  - `shouldRepaint => true`.

### 2.2.5 Buscador y FAB

Se aplicó idéntico patrón de V5:

- búsqueda en `AppBar.actions` + `bottomSheet`.
- FAB `FloatingActionButton.small` estilo Restricciones.

---

## 2.3 V7 (`hv7_screen.dart`) - Nuevo modelo

Archivo:
- `lib/features/control_hitos/presentation/screens/option_v7/hv7_screen.dart`

### 2.3.1 Base y naming

Se creó desde base funcional de V6, luego se renombró:

- clase pública: `Hv7Screen`
- estado: `_Hv7ScreenState`

### 2.3.2 Vista principal por defecto (requisito)

Se dejó como primera vista:

- `Matriz` tipo **tabla** (estética/estructura inspirada en HV2).

Implementación:

- en `TabBarView`:
  - primera página -> `_MatrizTabV2`
  - segunda página -> `_DataTab`

Widgets nuevos específicos para la matriz V7:

- `_MatrizTabV2`
- `_MatrixHeaderCellV2`
- `_MatrixRowV2`
- `_MatrixDatePillV2`
- `_MatrixEmptyRealV2`

Comportamiento:

- encabezado fijo de columnas (`Descripción`, `Contractual`, `Meta`, `Real`).
- filas alternadas.
- estado visual por color (en círculo de orden).
- abre detalle al tap.

### 2.3.3 Funcionalidad compartida con V5/V6

También integra:

- buscador en header superior derecho + barra inferior,
- diagrama de hitos,
- flujo de `conhit_general`,
- FAB estilo Restricciones.

---

## 3. Componentes/Patrones visuales estandarizados

## 3.1 FAB uniforme

Aplicado en V5/V6/V7:

```dart
FloatingActionButton.small(
  heroTag: 'add_hvX',
  backgroundColor: _D.primary,
  foregroundColor: _D.white,
  elevation: 2,
  onPressed: ...,
  child: const Icon(Icons.add_rounded),
)
```

## 3.2 Search UX uniforme (tipo Restricciones)

- Icono de búsqueda en `AppBar.actions`.
- Toggle:
  - `search_rounded` <-> `search_off_rounded`.
- Search input en `bottomSheet`.
- Al cerrar:
  - limpia query,
  - limpia controller.

---

## 4. Validación técnica ejecutada

Comando usado:

```bash
dart analyze \
  lib/features/control_hitos/presentation/screens/option_v5/hv5_screen.dart \
  lib/features/control_hitos/presentation/screens/option_v6/hv6_screen.dart \
  lib/features/control_hitos/presentation/screens/option_v7/hv7_screen.dart \
  lib/app/router.dart \
  lib/app/routes/route_names.dart \
  lib/features/projects/presentation/screens/hub_default_screen.dart
```

Resultado:

- Sin errores bloqueantes.
- Quedaron solo lints de tipo `info` (no rompen build).

---

## 5. Archivos modificados (inventario)

- `lib/app/routes/route_names.dart`
- `lib/app/router.dart`
- `lib/features/projects/presentation/screens/hub_default_screen.dart`
- `lib/features/control_hitos/presentation/screens/option_v5/hv5_screen.dart`
- `lib/features/control_hitos/presentation/screens/option_v6/hv6_screen.dart`
- `lib/features/control_hitos/presentation/screens/option_v7/hv7_screen.dart` (nuevo)

---

## 6. Notas para siguiente iteración

- Si se desea “copia 1:1” visual completa con Acta para búsqueda inline dentro del título (no bottom sheet), se puede migrar a `title` dinámico en `AppBar`.
- Se puede unificar `_SearchBar` en un componente compartido para V5/V6/V7 y reducir duplicación.
- Se pueden limpiar lints de `use_build_context_synchronously` y `unnecessary_underscores` sin cambiar comportamiento funcional.

