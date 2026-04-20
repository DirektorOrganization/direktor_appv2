# Avance Grafico - Especificacion Funcional/Tecnica para App Movil

## Objetivo

Este documento resume el modulo actual de Avance Grafico que ya existe en la aplicacion web, para usarlo como base de implementacion en la app movil Flutter.

La referencia funcional actual es la version vigente del modulo, no el rediseño:

- `vue/src/views/execution/AvanceGrafico.vue`
- `vue/src/views/execution/AddAvanceGrafico.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase1.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase2.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase3.vue`

## 1. Vista general del modulo

El modulo de Avance Grafico trabaja sobre un registro maestro por proyecto (`avagra_avancegrafico`) y se divide en 3 fases:

1. Fase 1: configuracion y control de posiciones/panos por lados y niveles.
2. Fase 2: control matricial de actividades por pisos y sectores.
3. Fase 3: control detallado por piso, sector y actividad, con posibilidad de plano.

Adicionalmente, el modulo maneja:

- acceso de integrantes al modulo;
- resumen general por fases;
- preferencia de vista del resumen (`vistaSeleccionada`);
- catalogos de estados, forma, sentido horario y tipo de lado;
- generacion de documentos en Fase 1 y Fase 2.

## 2. Flujo funcional actual

### 2.1 Listado inicial del modulo

Pantalla base: `AvanceGrafico.vue`

Objetivo:

- listar los proyectos a los que el usuario puede entrar en Avance Grafico;
- mostrar integrantes del proyecto;
- marcar quienes tienen acceso al modulo;
- habilitar/deshabilitar acceso al modulo por integrante;
- cambiar estado general del modulo.

API principal:

- `POST /avagra/get_avancesgraficos`
- `PATCH /avagra/update_estado_avancegrafico`
- `PATCH /avagra/update_acceso_integrante`
- `PATCH /avagra/update_acceso_integrantes`

Logica relevante:

- si el proyecto aun no tiene registro en `avagra_avancegrafico`, el backend lo crea;
- el acceso real al modulo por integrante se guarda en `avagra_integrantes`;
- la lista se cruza con `proy_proyecto`, `proy_integrantes` y tambien con `actreu_integrantes` para casos de invitados.

### 2.2 Menu resumen de fases

Pantalla base: `AddAvanceGrafico.vue`

Objetivo:

- mostrar resumen de Fase 1, Fase 2 y Fase 3;
- abrir cada fase;
- guardar la vista de resumen preferida.

API principal:

- `POST /avagra/get_resumen_fases`
- `PATCH /avagra/update_vista_seleccionada`

`vistaSeleccionada`:

- `0`: vista principal basada en completados;
- `1`: vista principal basada en aprobados por calidad/finalizados.

Nota:

Aunque la preferencia se guarda en el maestro, el backend hoy devuelve para Fase 2 y Fase 3 ambos conteos principales.

### 2.3 Fase 1

Pantalla base: `AvanceGraficoFase1.vue`

Objetivo funcional:

Deseamos tener una vista grafica donde se representara el sotano de un edificio , como una figura de cuatro lados en el medio  en cada uno de sus lados se tendra las secciones que este pudiera tener por piso. Para esto
la cantidad de piso se define como Niveles y los paños son la cantidad de secciones en la horizontal se tendra.

Para definir correctamente la figura se requiere de los siguiente : 


- definir la forma central del grafico : (rectangular  horizontal, ohrizontal vertical , cuadrado)
- definir el sentido de recorrido;
- definir la generacion de las secciones por cada uno de los lados (arriba , abajo , izquierda ,  derehca)
   * dentro defijniremos la cantidad nde niveles (pisos hacia abajo)
   * dentro definiremos la cantidad  de paños  (la cantidad horizonta de secciones)

- administrar el estado de cada posicion individual;


Modelo conceptual:

- existe una fase (`avagra_faseuno`);
- dentro de ella hay secciones (`avagra_secciones`);
- cada seccion contiene posiciones (`avagra_posiciones`);
- cada posicion representa una celda/pano puntual de seguimiento.

APIs principales:

- `POST /avagra/get_fase_uno`
- `POST /avagra/fase_uno/set_forma`
- `POST /avagra/fase_uno/set_sentido`
- `POST /avagra/fase_uno/set_tipos_lado_secciones`
- `POST /avagra/fase_uno/edit_section`
- `POST /avagra/fase_uno/edit_position_status`
- `POST /avagra/fase_uno/edit_positions_status`

Resumen funcional calculado:

- total de posiciones validas;
- total completadas;
- avance por nivel.

Reglas importantes:

- se ignoran posiciones con estado `No Aplica` (`codEstado = 4`);
- una posicion se considera completada cuando `codEstado = 2`;
- si la fase existe pero no tiene secciones, el backend crea secciones por defecto.

### 2.4 Fase 2

Pantalla base: `AvanceGraficoFase2.vue`

Objetivo funcional:

Mostra de alguna grafica la representacion en edificio de cada una de las actividades , entendiendo que las actividades tienen sectores y ovbiamente la cantidad de sotanos .

- crear actividades;
- por cada actividad, definir matriz de pisos y sectores;
- marcar estados de uno o varios cuadros;
- soportar sotanos;
- manejar opcion de pisos uniformes;
- manejar fotos/documentos de la fase.

Modelo conceptual:

- existe una fase (`avagra_fasedos`);
- la fase tiene actividades (`avagra_actividades`);
- cada actividad genera cuadros (`avagra_cuadros`);
- cada cuadro representa una celda de control por piso y sector;
- la fase tambien puede tener fotos/documentos (`avagra_fotos`).

APIs principales:

- `POST /avagra/fase_dos/get_fase_dos`
- `POST /avagra/fase_dos/set_pisos_uniformes`
- `POST /avagra/fase_dos/store_actividad`
- `POST /avagra/fase_dos/update_actividad`
- `POST /avagra/fase_dos/update_lista_cuadros`
- `DELETE /avagra/fase_dos/delete_actividad`

Reglas importantes:

- si `flgPisosUniformes = 1`, el numero de pisos para nuevas actividades sale de `numPisosUniformes`;
- cada actividad puede tener su propia cantidad de pisos, sectores y sotanos;
- el resumen considera solo cuadros validos dentro del rango real de la actividad;
- `Completado` en Fase 2 es `codEstado = 7`;
- `Aprobado por Calidad` en Fase 2 es `codEstado = 8`;
- `No Aplica` en Fase 2 es `codEstado = 10`.

### 2.5 Fase 3

Pantalla base: `AvanceGraficoFase3.vue`

Objetivo funcional:

Se debe de crear algun tipo de manejador que permite : 

- construir una estructura por pisos;
- registrar sectores por piso;
- registrar actividades por piso;
- cruzar actividad x sector x piso como unidad final de control;
- ubicar sectores sobre un plano (por cada piso tendremos la opcion  de camnbiar a la vista de planos)
- subir plano por piso y ubicar cada seccion en elgun punto del plano.

Modelo conceptual:

1. `avagra_fasetres`: cabecera de fase.
2. `avagra_pisos`: pisos/sotanos.
3. `avagra_sectores`: catalogo/logica de sector.
4. `avagra_sectoresxpisos`: sector instanciado dentro de un piso.
5. `avagra_actividad`: catalogo/logica de actividad.
6. `avagra_actividadxpisos`: actividad instanciada dentro de un piso.
7. `avagra_actividadxsectorxpisos`: celda final de control de avance.

APIs principales:

- `POST /avagra/fase_tres/get-fase-tres`
- `POST /avagra/fase_tres/crear-datos-iniciales`
- `POST /avagra/fase_tres/create-sector`
- `PATCH /avagra/fase_tres/update-sector`
- `DELETE /avagra/fase_tres/delete-sector`
- `POST /avagra/fase_tres/create-actividad`
- `PATCH /avagra/fase_tres/update-actividad`
- `DELETE /avagra/fase_tres/delete-actividad`
- `PATCH /avagra/fase_tres/update-estado-actividades`
- `POST /avagra/fase_tres/subir-plano`
- `POST /avagra/fase_tres/actualizar-posicion-sector`
- `POST /avagra/fase_tres/update-orden-actividad`

Reglas importantes:

- los sotanos se guardan en `avagra_pisos.numOrden` con valores negativos;
- el estado real de avance se controla en `avagra_actividadxsectorxpisos`;
- para resumen de Fase 3:
  - `Completado` = `codEstado 13`;
  - `Aprobado por Calidad` = `codEstado 14`;
  - `No Aplica` = `codEstado 16` y no entra al total.

## 3. Modelo de base de datos utilizado por Avance Grafico

## 3.1 Tabla maestra

### `avagra_avancegrafico`

Registro maestro del modulo por proyecto.

Campos principales:

- `codAvaGrafico`: PK.
- `codProyecto`: FK al proyecto.
- `codEstado`: estado general del modulo.
- `dayFechaCreacion`
- `desUsuarioCreacion`
- `vistaSeleccionada`: preferencia de vista del resumen.

Uso funcional:

- es el pivote de todo el modulo;
- desde aqui cuelgan integrantes y las 3 fases;
- si la app movil entra al modulo, este registro es la llave principal junto con `codProyecto`.

### `avagra_integrantes`

Controla que integrantes del proyecto tienen acceso al modulo.

Campos principales:

- `codProyecto`
- `codAvaGrafico`
- `codProyIntegrante`
- `codEstado`
- auditoria de creacion/modificacion

Uso funcional:

- `codEstado = 1`: integrante habilitado;
- otro valor: integrante no habilitado o deshabilitado;
- esta tabla no reemplaza la pertenencia al proyecto; solo controla acceso a Avance Grafico.

## 3.2 Catalogos del modulo

### `avagra_estados`

Catalogo transversal de estados del modulo.

Campos:

- `codEstado`
- `desEstado`
- `desFase`
- `codColor`
- `desColor`

Catalogo actual relevante:

#### Fase 1 (`desFase = FaseUno_Posiciones`)

- `1`: Pendiente
- `2`: Completado
- `3`: Programado Sem. Actual
- `4`: No Aplica

#### Fase 2 (`desFase = FaseDos_Cuadros`)

- `5`: Pendiente
- `6`: En proceso
- `7`: Completado
- `8`: Aprobado por Calidad
- `9`: Programado Sem. Actual
- `10`: No Aplica

#### Fase 3 (`desFase = FaseTres_ActividadesXSectores`)

- `11`: Pendiente
- `12`: En proceso
- `13`: Completado
- `14`: Aprobado por Calidad
- `15`: Programado Sem. Actual
- `16`: No Aplica

### `avagra_forma`

Define la geometria base de la Fase 1.

- `1`: Rectangulo Vertical
- `2`: Rectangulo Horizontal
- `3`: Cuadrado

### `avagra_sentidohorario`

Define el sentido de recorrido.

- `1`: Horario
- `2`: Antihorario

### `avagra_tipolado`

Define el tipo de lado de una seccion.

- `1`: Superior
- `2`: Inferior
- `3`: Izquierda
- `4`: Derecha

## 3.3 Tablas de Fase 1

### `avagra_faseuno`

Cabecera de la fase.

Campos principales:

- `codFaseUno`
- `codProyecto`
- `codAvaGrafico`
- `DesFaseUno`
- `Comentarios`
- `desResOrdenTipoLados`
- `CodForma`
- `CodSentido`
- `auto_generate_pdf_enabled`
- `auto_generate_pdf_iso_day`
- `auto_generate_pdf_hours`

Uso funcional:

- guarda la configuracion general de la figura;
- guarda si la generacion automatica de PDF esta habilitada;
- referencia la forma y el sentido.

### `avagra_secciones`

Cada lado/bloque principal del grafico de Fase 1.

Campos principales:

- `codSecciones`
- `desSecciones`
- `desAbrev`
- `numNiveles`
- `numPanios`
- `numOrdenTipoLado`
- `CodTipoLado`
- `codFaseUno`
- `codProyecto`
- `codAvaGrafico`

Uso funcional:

- `numNiveles`: cantidad vertical de celdas de esa seccion;
- `numPanios`: cantidad horizontal de celdas;
- `CodTipoLado`: superior, inferior, izquierda o derecha;
- `numOrdenTipoLado`: orden visual/logico de la seccion dentro del lado.

### `avagra_posiciones`

Unidad minima editable de Fase 1.

Campos principales:

- `codPosition`
- `codSecciones`
- `desNumeracion`
- `numNivel`
- `numPanio`
- `desPosicion`
- `desAbrev`
- `codEstado`

Uso funcional:

- cada registro es una celda concreta;
- `numNivel` ubica la fila/nivel;
- `numPanio` ubica el pano/columna;
- `codEstado` controla color y estado operativo.

### `avagra_faseunodocumentos`

Documentos generados o asociados a Fase 1.

Uso funcional:

- soporte de generacion, historial y descarga documental de la fase.

## 3.4 Tablas de Fase 2

### `avagra_fasedos`

Cabecera de Fase 2.

Campos principales:

- `codFaseDos`
- `codProyecto`
- `codAvaGrafico`
- `desFaseDos`
- `desComentarios`
- `flgPisosUniformes`
- `numPisosUniformes`
- `auto_generate_pdf_enabled`
- `auto_generate_pdf_iso_day`
- `auto_generate_pdf_hours`

Uso funcional:

- parametriza si todas las actividades comparten la misma cantidad de pisos;
- centraliza la configuracion documental de la fase.

### `avagra_actividades`

Actividad configurable de Fase 2.

Campos principales:

- `codActividades`
- `desActividades`
- `desAbrev`
- `numPisos`
- `numSectores`
- `sotanos`
- `codFaseDos`
- `codProyecto`
- `codAvaGrafico`
- `codEstado`

Uso funcional:

- define la malla de cuadros a generar para una actividad;
- `sotanos` extiende la matriz a indices negativos de piso;
- si cambian `numPisos`, `numSectores` o `sotanos`, los cuadros deben recalcularse.

### `avagra_cuadros`

Unidad minima editable de Fase 2.

Campos principales:

- `codCuadros`
- `codActividades`
- `numOrden`
- `numPiso`
- `numSector`
- `codEstado`

Uso funcional:

- cada registro representa una celda de actividad x piso x sector;
- `numPiso` y `numSector` ubican la celda;
- `numOrden` ayuda a mantener orden de dibujado/listado.

### `avagra_fotos`

Fotos o documentos asociados a Fase 2.

Campos principales:

- `codFoto`
- `desFoto`
- `desUrl`
- `codFaseDos`
- `codProyecto`
- `codAvaGrafico`

Uso funcional:

- adjuntos o productos documentales visibles desde la fase.

## 3.5 Tablas de Fase 3

### `avagra_fasetres`

Cabecera de Fase 3.

Campos principales:

- `codFaseTres`
- `codProyecto`
- `codAvaGrafico`
- `desFaseTres`
- `desComentarios`
- `numPisos`
- `numSectores`
- `numActividades`

Uso funcional:

- almacena el tamano resumido de la estructura creada.

### `avagra_pisos`

Pisos o sotanos de la fase.

Campos principales:

- `codPiso`
- `codFaseTres`
- `codProyecto`
- `codAvaGrafico`
- `desAbrev`
- `desNombre`
- `numOrden`
- `desLinkPlano`
- `desNombrePlano`

Uso funcional:

- `numOrden < 0`: sotano;
- `numOrden > 0`: piso;
- `desLinkPlano` y `desNombrePlano` guardan el plano del piso.

### `avagra_sectores`

Entidad sector usada por Fase 3.

Campos principales:

- `codSector`
- `codFaseTres`
- `codProyecto`
- `codAvaGrafico`
- `desNombre`
- `desDescripcion`

Uso funcional:

- sirve como base de sector; luego se instancia por piso.

### `avagra_sectoresxpisos`

Sector instanciado dentro de un piso concreto.

Campos principales:

- `codSectorxPiso`
- `codPiso`
- `codSector`
- `desNombre`
- `desDescripcion`
- `codEstado`
- `numPorcentajeCompletados`
- `numPorcentajeAprobadosCalidad`
- `jsonPosicionamientoPlano`

Uso funcional:

- representa el sector visible y editable en un piso;
- `jsonPosicionamientoPlano` guarda posicion/tamano referencial sobre el plano;
- los porcentajes son agregados calculados del detalle interno.

### `avagra_actividad`

Catalogo/logica de actividad de Fase 3.

Campos principales:

- `codActividad`
- `codFaseTres`
- `codProyecto`
- `codAvaGrafico`
- `desNombre`
- `desDescripcion`

### `avagra_actividadxpisos`

Actividad instanciada en un piso concreto.

Campos principales:

- `codActividadxPiso`
- `codActividad`
- `codPiso`
- `desAbrev`
- `desDescripcion`
- `codEstado`
- `numOrden`

Uso funcional:

- ordena actividades dentro de cada piso;
- sirve de padre inmediato para el detalle por sector.

### `avagra_actividadxsectorxpisos`

Unidad minima editable de Fase 3.

Campos principales:

- `codActividadxSectorxPiso`
- `codActividadxPiso`
- `codSectorxPiso`
- `codEstado`

Uso funcional:

- representa el estado real final de una actividad en un sector de un piso;
- este es el registro que se actualiza para marcar avance.

## 4. Relacion de campos con la logica funcional/tecnica

## 4.1 Identificadores maestros

- `codProyecto`: llave del proyecto en todo el modulo.
- `codAvaGrafico`: llave maestra del modulo de Avance Grafico dentro del proyecto.
- `codFaseUno`, `codFaseDos`, `codFaseTres`: cabeceras por fase.

Implementacion movil:

- conviene persistir siempre `codProyecto`, `codAvaGrafico` y el `email` del usuario autenticado;
- en cada fase, persistir tambien el codigo de fase devuelto por backend.

## 4.2 Campos que gobiernan la visualizacion

### Fase 1

- `CodForma`: define si la distribucion base es vertical, horizontal o cuadrada.
- `CodSentido`: define el orden de lectura/recorrido.
- `CodTipoLado`: define lado superior, inferior, izquierdo o derecho.
- `numNiveles`: altura de la seccion.
- `numPanios`: ancho de la seccion.
- `numOrdenTipoLado`: orden interno dentro del lado.

### Fase 2

- `numPisos`: filas activas hacia arriba.
- `sotanos`: filas activas hacia abajo.
- `numSectores`: columnas activas.
- `flgPisosUniformes` y `numPisosUniformes`: comportamiento global de creacion de actividades.

### Fase 3

- `numOrden` en `avagra_pisos`: define el nivel real.
- `jsonPosicionamientoPlano`: ubica el sector en el plano.
- `numOrden` en `avagra_actividadxpisos`: orden de render/listado de actividades.

## 4.3 Campos que gobiernan estados

- `codEstado` en Fase 1: estado de posicion.
- `codEstado` en Fase 2: estado de cuadro.
- `codEstado` en Fase 3: estado de actividad por sector por piso.

La regla tecnica correcta es:

- nunca interpretar el numero por intuicion;
- siempre resolverlo con `avagra_estados` y por `desFase`.

## 4.4 Campos de resumen

- `vistaSeleccionada` en `avagra_avancegrafico`: preferencia del resumen general.
- `numPorcentajeCompletados` en `avagra_sectoresxpisos`: agregado por sector/piso.
- `numPorcentajeAprobadosCalidad` en `avagra_sectoresxpisos`: agregado por sector/piso.
- `numPisos`, `numSectores`, `numActividades` en `avagra_fasetres`: resumen estructural de la fase.

## 5. Tablas vinculadas a Avance Grafico que hoy se utilizan

## 5.1 Nucleo del modulo

- `avagra_avancegrafico`
- `avagra_integrantes`
- `avagra_estados`
- `avagra_forma`
- `avagra_sentidohorario`
- `avagra_tipolado`

## 5.2 Fase 1

- `avagra_faseuno`
- `avagra_secciones`
- `avagra_posiciones`
- `avagra_faseunodocumentos`

## 5.3 Fase 2

- `avagra_fasedos`
- `avagra_actividades`
- `avagra_cuadros`
- `avagra_fotos`

## 5.4 Fase 3

- `avagra_fasetres`
- `avagra_pisos`
- `avagra_sectores`
- `avagra_sectoresxpisos`
- `avagra_actividad`
- `avagra_actividadxpisos`
- `avagra_actividadxsectorxpisos`

## 5.5 Tablas externas vinculadas

Estas no pertenecen al modulo, pero hoy participan en su logica:

- `proy_proyecto`: proyecto base.
- `proy_integrantes`: integrantes del proyecto.
- `users`: resolucion de usuario por email y auditoria.
- `actreu_integrantes`: soporte de acceso por invitacion en el listado.
- tablas de funcionalidades por elemento de control: se usan para preferencias como zoom en Fase 1 y Fase 2.

## 6. Recomendacion de implementacion para Flutter

La app movil no deberia reconstruir la logica desde SQL directo. Lo correcto es consumir el backend actual y reflejar la misma semantica funcional.

Orden recomendado de implementacion:

1. Listado del modulo por proyecto.
2. Resumen de fases.
3. Fase 1 con lectura, configuracion y actualizacion de estados.
4. Fase 2 con actividades, cuadros y cambios masivos de estado.
5. Fase 3 con lectura estructural, cambio de estados y plano.

Datos minimos que la app debe manejar por contexto:

- `codProyecto`
- `codAvaGrafico`
- `email` del usuario
- `codFaseUno` / `codFaseDos` / `codFaseTres` segun fase cargada

## 7. Checklist funcional para el modulo movil

### Base

- listar proyectos con Avance Grafico;
- visualizar integrantes habilitados del modulo;
- guardar cambio de `vistaSeleccionada`.

### Fase 1

- cargar configuracion y estados;
- editar forma y sentido;
- editar secciones;
- cambiar estado de una o varias posiciones;
- mostrar resumen por nivel.

### Fase 2

- listar actividades;
- crear/editar/eliminar actividad;
- cambiar estado de uno o varios cuadros;
- respetar pisos, sectores y sotanos;
- mostrar resumen por actividad y total.

### Fase 3

- cargar pisos, sectores y actividades;
- crear data inicial;
- editar sectores y actividades;
- cambiar estados por lote;
- soportar plano y posicionamiento de sectores.

## 8. Fuentes primarias revisadas

- `backup_db/dump-u278888007_direktor2_des-202604070146_bdnueva.fixed.sql`
- `routes/api.php`
- `app/Http/Controllers/AvaGraController.php`
- `app/Http/Controllers/AvaGraFaseTresController.php`
- `app/Services/AvanceGrafico/FaseService.php`
- `app/Services/AvanceGrafico/AvagraResumenService.php`
- `app/Models/AvanceGrafico/*`
- `vue/src/store/modules/avanceGrafico.js`
- `vue/src/views/execution/AvanceGrafico.vue`
- `vue/src/views/execution/AddAvanceGrafico.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase1.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase2.vue`
- `vue/src/components/avanceGrafico/AvanceGraficoFase3.vue`
