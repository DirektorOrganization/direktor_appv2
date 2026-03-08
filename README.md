# direktor_appv2

Aplicacion movil de Direktor construida en Flutter. Este proyecto se esta desarrollando por iteraciones, tomando como base los wireframes funcionales, la estructura del proyecto definida para Flutter y el modelo SQLite de la aplicacion movil.

## Objetivo

Construir una app movil corporativa para Direktor que permita gestionar proyectos, analisis de restricciones y actas de reuniones, con una interfaz moderna, formal y alineada a la identidad visual de la marca.

## Alcance actual

En la iteracion actual se ha trabajado principalmente el frontend y la experiencia visual:

- Splash, login y hub de proyectos.
- Vista de proyectos con indicadores de analisis de restricciones y actas de reuniones.
- Lista de restricciones con filtros, cambio de estado y acceso a creacion.
- Vista detalle de restriccion con estilo renovado.
- Vista crear/editar restriccion con campos tipo select y selector de fecha.
- Integracion visual del logo real de Direktor en la app y en el splash nativo de Android.

## Stack

- Flutter
- Dart
- SQLite como base de datos local prevista para la app
- Android resources para splash y branding nativo

## Estructura relevante

- `lib/app/`: arranque de aplicacion, router y tema.
- `lib/features/`: modulos funcionales por dominio.
- `lib/shared/`: widgets y utilidades reutilizables.
- `assets/db/`: esquema SQLite de referencia.
- `assets/Iimages/`: recursos graficos usados por la app.
- `android/app/src/main/res/`: splash y recursos nativos Android.

## Estado del desarrollo

El proyecto se encuentra en fase de construccion del frontend base. La linea visual principal ya fue ajustada a la identidad de Direktor usando azul corporativo y acentos naranja. La siguiente etapa puede enfocarse en conectar estas pantallas a modelos, datasource, repositorios y persistencia SQLite.

## Flujo de trabajo

Las entregas se estan separando por ramas de iteracion para mantener control de avances y validacion progresiva.

- `codex/iteracion1`: base visual inicial y ajustes de frontend.
- `codex/iteracion2`: siguiente fase de trabajo a partir de la base aprobada.
