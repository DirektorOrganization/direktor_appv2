-- MODELO CURADO DEL MODULO AVANCE GRAFICO PARA APP MOVIL
-- Fuente: backup_db/dump-u278888007_direktor2_des-202604070146_bdnueva.fixed.sql
-- Fecha de extraccion: 2026-04-19
-- Incluye tablas avagra_* y tablas externas vinculadas al modulo

    -- ----------------------------------------------------------------
-- TABLE: avagra_avancegrafico
-- ----------------------------------------------------------------
CREATE TABLE `avagra_avancegrafico` (
  `codAvaGrafico` bigint(20) NOT NULL AUTO_INCREMENT,
  `codProyecto` bigint(20) NOT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `vistaSeleccionada` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`codAvaGrafico`,`codProyecto`),
  KEY `codProyecto` (`codProyecto`),
  CONSTRAINT `avagra_avancegrafico_ibfk_1` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------
-- TABLE: avagra_integrantes
-- ----------------------------------------------------------------
CREATE TABLE `avagra_integrantes` (
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `codProyIntegrante` bigint(20) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  UNIQUE KEY `codProyecto` (`codProyecto`,`codAvaGrafico`,`codProyIntegrante`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_actividad
-- ----------------------------------------------------------------
CREATE TABLE `avagra_actividad` (
  `codActividad` bigint(20) NOT NULL AUTO_INCREMENT,
  `codFaseTres` bigint(20) DEFAULT NULL,
  `codProyecto` bigint(20) DEFAULT NULL,
  `codAvaGrafico` bigint(20) DEFAULT NULL,
  `desNombre` varchar(250) DEFAULT NULL,
  `desDescripcion` varchar(250) DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codActividad`),
  KEY `codFaseTres` (`codFaseTres`,`codProyecto`,`codAvaGrafico`),
  CONSTRAINT `avagra_actividad_ibfk_1` FOREIGN KEY (`codFaseTres`, `codProyecto`, `codAvaGrafico`) REFERENCES `avagra_fasetres` (`codFaseTres`, `codProyecto`, `codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_actividades
-- ----------------------------------------------------------------
CREATE TABLE `avagra_actividades` (
  `codActividades` bigint(20) NOT NULL AUTO_INCREMENT,
  `desActividades` varchar(150) DEFAULT NULL,
  `numPisos` int(11) DEFAULT NULL,
  `sotanos` int(11) DEFAULT 0,
  `numSectores` int(11) DEFAULT NULL,
  `codFaseDos` bigint(20) DEFAULT NULL,
  `codProyecto` bigint(20) DEFAULT NULL,
  `codAvaGrafico` bigint(20) DEFAULT NULL,
  `codUsuarioCreacion` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` int(11) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `desAbrev` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`codActividades`),
  KEY `codFaseDos` (`codFaseDos`,`codProyecto`,`codAvaGrafico`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_actividades_ibfk_1` FOREIGN KEY (`codFaseDos`, `codProyecto`, `codAvaGrafico`) REFERENCES `avagra_fasedos` (`codFaseDos`, `codProyecto`, `codAvaGrafico`),
  CONSTRAINT `avagra_actividades_ibfk_2` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_actividadxpisos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_actividadxpisos` (
  `codActividadxPiso` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActividad` bigint(20) NOT NULL,
  `codPiso` bigint(20) NOT NULL,
  `desAbrev` varchar(250) DEFAULT NULL,
  `desDescripcion` varchar(250) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `numOrden` int(11) DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codActividadxPiso`),
  UNIQUE KEY `codActividadxPiso` (`codActividadxPiso`,`codActividad`,`codPiso`),
  KEY `codActividad` (`codActividad`),
  KEY `codPiso` (`codPiso`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_actividadxpisos_ibfk_1` FOREIGN KEY (`codActividad`) REFERENCES `avagra_actividad` (`codActividad`),
  CONSTRAINT `avagra_actividadxpisos_ibfk_2` FOREIGN KEY (`codPiso`) REFERENCES `avagra_pisos` (`codPiso`),
  CONSTRAINT `avagra_actividadxpisos_ibfk_3` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_actividadxsectorxpisos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_actividadxsectorxpisos` (
  `codActividadxSectorxPiso` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActividadxPiso` bigint(20) NOT NULL,
  `codSectorxPiso` bigint(20) NOT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codActividadxSectorxPiso`),
  UNIQUE KEY `codActividadxPiso` (`codActividadxPiso`,`codSectorxPiso`),
  KEY `codSectorxPiso` (`codSectorxPiso`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_actividadxsectorxpisos_ibfk_1` FOREIGN KEY (`codActividadxPiso`) REFERENCES `avagra_actividadxpisos` (`codActividadxPiso`),
  CONSTRAINT `avagra_actividadxsectorxpisos_ibfk_2` FOREIGN KEY (`codSectorxPiso`) REFERENCES `avagra_sectoresxpisos` (`codSectorxPiso`),
  CONSTRAINT `avagra_actividadxsectorxpisos_ibfk_3` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------
-- TABLE: avagra_cuadros
-- ----------------------------------------------------------------
CREATE TABLE `avagra_cuadros` (
  `codCuadros` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActividades` bigint(20) DEFAULT NULL,
  `numOrden` int(11) DEFAULT NULL,
  `numPiso` int(11) DEFAULT NULL,
  `numSector` int(11) DEFAULT NULL,
  `codUsuarioCreacion` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` int(11) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  PRIMARY KEY (`codCuadros`),
  KEY `codActividades` (`codActividades`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_cuadros_ibfk_1` FOREIGN KEY (`codActividades`) REFERENCES `avagra_actividades` (`codActividades`),
  CONSTRAINT `avagra_cuadros_ibfk_2` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=135 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_estados
-- ----------------------------------------------------------------
CREATE TABLE `avagra_estados` (
  `codEstado` int(11) NOT NULL AUTO_INCREMENT,
  `desEstado` varchar(150) DEFAULT NULL,
  `desFase` varchar(255) DEFAULT NULL,
  `codColor` varchar(10) DEFAULT NULL,
  `desColor` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_fasedos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_fasedos` (
  `codFaseDos` bigint(20) NOT NULL AUTO_INCREMENT,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `desFaseDos` varchar(150) DEFAULT NULL,
  `desComentarios` text DEFAULT NULL,
  `flgPisosUniformes` bit(1) DEFAULT NULL,
  `numPisosUniformes` int(11) DEFAULT NULL,
  `auto_generate_pdf_enabled` tinyint(1) DEFAULT 0,
  `auto_generate_pdf_iso_day` tinyint(4) DEFAULT NULL,
  `auto_generate_pdf_hours` text DEFAULT NULL,
  PRIMARY KEY (`codFaseDos`,`codProyecto`,`codAvaGrafico`),
  KEY `codProyecto` (`codProyecto`),
  KEY `codAvaGrafico` (`codAvaGrafico`),
  CONSTRAINT `avagra_fasedos_ibfk_1` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`),
  CONSTRAINT `avagra_fasedos_ibfk_2` FOREIGN KEY (`codAvaGrafico`) REFERENCES `avagra_avancegrafico` (`codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_fasetres
-- ----------------------------------------------------------------
CREATE TABLE `avagra_fasetres` (
  `codFaseTres` bigint(20) NOT NULL AUTO_INCREMENT,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `desFaseTres` varchar(250) DEFAULT NULL,
  `desComentarios` text DEFAULT NULL,
  `numPisos` int(11) DEFAULT NULL,
  `numSectores` int(11) DEFAULT NULL,
  `numActividades` int(11) DEFAULT NULL,
  PRIMARY KEY (`codFaseTres`),
  UNIQUE KEY `codFaseTres` (`codFaseTres`,`codProyecto`,`codAvaGrafico`),
  KEY `codProyecto` (`codProyecto`),
  KEY `codAvaGrafico` (`codAvaGrafico`),
  CONSTRAINT `avagra_fasetres_ibfk_1` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`),
  CONSTRAINT `avagra_fasetres_ibfk_2` FOREIGN KEY (`codAvaGrafico`) REFERENCES `avagra_avancegrafico` (`codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_faseuno
-- ----------------------------------------------------------------
CREATE TABLE `avagra_faseuno` (
  `codFaseUno` bigint(20) NOT NULL AUTO_INCREMENT,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `DesFaseUno` varchar(100) DEFAULT NULL,
  `Comentarios` text DEFAULT NULL,
  `desResOrdenTipoLados` varchar(150) DEFAULT NULL,
  `CodForma` int(11) DEFAULT NULL,
  `CodSentido` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(150) DEFAULT NULL,
  `auto_generate_pdf_enabled` tinyint(1) DEFAULT 0,
  `auto_generate_pdf_iso_day` tinyint(4) DEFAULT NULL,
  `auto_generate_pdf_hours` text DEFAULT NULL,
  PRIMARY KEY (`codFaseUno`),
  KEY `codProyecto` (`codProyecto`),
  KEY `codAvaGrafico` (`codAvaGrafico`),
  KEY `CodForma` (`CodForma`),
  KEY `CodSentido` (`CodSentido`),
  CONSTRAINT `avagra_faseuno_ibfk_1` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`),
  CONSTRAINT `avagra_faseuno_ibfk_2` FOREIGN KEY (`codAvaGrafico`) REFERENCES `avagra_avancegrafico` (`codAvaGrafico`),
  CONSTRAINT `avagra_faseuno_ibfk_3` FOREIGN KEY (`CodForma`) REFERENCES `avagra_forma` (`CodForma`),
  CONSTRAINT `avagra_faseuno_ibfk_4` FOREIGN KEY (`CodSentido`) REFERENCES `avagra_sentidohorario` (`CodSentido`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_faseunodocumentos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_faseunodocumentos` (
  `codFaseUnoDocumentos` bigint(20) NOT NULL AUTO_INCREMENT,
  `desNombre` varchar(50) DEFAULT NULL,
  `desLink` varchar(150) DEFAULT NULL,
  `codFaseUno` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioCreacion` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`codFaseUnoDocumentos`),
  KEY `codFaseUno` (`codFaseUno`),
  KEY `codProyecto` (`codProyecto`),
  KEY `codAvaGrafico` (`codAvaGrafico`),
  CONSTRAINT `avagra_faseunodocumentos_ibfk_1` FOREIGN KEY (`codFaseUno`) REFERENCES `avagra_faseuno` (`codFaseUno`),
  CONSTRAINT `avagra_faseunodocumentos_ibfk_2` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`),
  CONSTRAINT `avagra_faseunodocumentos_ibfk_3` FOREIGN KEY (`codAvaGrafico`) REFERENCES `avagra_avancegrafico` (`codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_forma
-- ----------------------------------------------------------------
CREATE TABLE `avagra_forma` (
  `CodForma` int(11) NOT NULL AUTO_INCREMENT,
  `DesForma` varchar(150) DEFAULT NULL,
  `DesAbrev` varchar(50) DEFAULT NULL,
  `DesIcon` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CodForma`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_fotos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_fotos` (
  `codFoto` bigint(20) NOT NULL AUTO_INCREMENT,
  `codFaseDos` bigint(20) DEFAULT NULL,
  `codProyecto` bigint(20) DEFAULT NULL,
  `codAvaGrafico` bigint(20) DEFAULT NULL,
  `desFoto` varchar(100) DEFAULT NULL,
  `desUrl` text DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioCreacion` int(11) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` int(11) DEFAULT NULL,
  PRIMARY KEY (`codFoto`),
  KEY `codFaseDos` (`codFaseDos`,`codProyecto`,`codAvaGrafico`),
  CONSTRAINT `avagra_fotos_ibfk_1` FOREIGN KEY (`codFaseDos`, `codProyecto`, `codAvaGrafico`) REFERENCES `avagra_fasedos` (`codFaseDos`, `codProyecto`, `codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ----------------------------------------------------------------
-- TABLE: avagra_pisos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_pisos` (
  `codPiso` bigint(20) NOT NULL AUTO_INCREMENT,
  `codFaseTres` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `desAbrev` varchar(250) DEFAULT NULL,
  `desNombre` varchar(250) DEFAULT NULL,
  `numOrden` int(11) DEFAULT NULL,
  `desLinkPlano` varchar(250) DEFAULT NULL,
  `desNombrePlano` varchar(250) DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codPiso`),
  KEY `codFaseTres` (`codFaseTres`,`codProyecto`,`codAvaGrafico`),
  CONSTRAINT `avagra_pisos_ibfk_1` FOREIGN KEY (`codFaseTres`, `codProyecto`, `codAvaGrafico`) REFERENCES `avagra_fasetres` (`codFaseTres`, `codProyecto`, `codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_posiciones
-- ----------------------------------------------------------------
CREATE TABLE `avagra_posiciones` (
  `codPosition` int(11) NOT NULL AUTO_INCREMENT,
  `codSecciones` bigint(20) NOT NULL,
  `desNumeracion` varchar(150) DEFAULT NULL,
  `numNivel` int(11) DEFAULT NULL,
  `numPanio` int(11) DEFAULT NULL,
  `desPosicion` varchar(150) DEFAULT NULL,
  `desAbrev` varchar(50) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `codUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codPosition`),
  KEY `codSecciones` (`codSecciones`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_posiciones_ibfk_1` FOREIGN KEY (`codSecciones`) REFERENCES `avagra_secciones` (`codSecciones`),
  CONSTRAINT `avagra_posiciones_ibfk_2` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=116 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_secciones
-- ----------------------------------------------------------------
CREATE TABLE `avagra_secciones` (
  `codSecciones` bigint(20) NOT NULL AUTO_INCREMENT,
  `desSecciones` varchar(150) DEFAULT NULL,
  `desAbrev` varchar(50) DEFAULT NULL,
  `numNiveles` int(11) DEFAULT NULL,
  `numPanios` int(11) DEFAULT NULL,
  `numOrdenTipoLado` int(11) DEFAULT NULL,
  `CodTipoLado` int(11) DEFAULT NULL,
  `codFaseUno` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `codAvaGrafico` bigint(20) NOT NULL,
  `codUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codSecciones`),
  KEY `CodTipoLado` (`CodTipoLado`),
  KEY `codFaseUno` (`codFaseUno`),
  KEY `codProyecto` (`codProyecto`),
  KEY `codAvaGrafico` (`codAvaGrafico`),
  CONSTRAINT `avagra_secciones_ibfk_1` FOREIGN KEY (`CodTipoLado`) REFERENCES `avagra_tipolado` (`CodTipoLado`),
  CONSTRAINT `avagra_secciones_ibfk_2` FOREIGN KEY (`codFaseUno`) REFERENCES `avagra_faseuno` (`codFaseUno`),
  CONSTRAINT `avagra_secciones_ibfk_3` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`),
  CONSTRAINT `avagra_secciones_ibfk_4` FOREIGN KEY (`codAvaGrafico`) REFERENCES `avagra_avancegrafico` (`codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_sectores
-- ----------------------------------------------------------------
CREATE TABLE `avagra_sectores` (
  `codSector` bigint(20) NOT NULL AUTO_INCREMENT,
  `codFaseTres` bigint(20) DEFAULT NULL,
  `codProyecto` bigint(20) DEFAULT NULL,
  `codAvaGrafico` bigint(20) DEFAULT NULL,
  `desNombre` varchar(250) DEFAULT NULL,
  `desDescripcion` varchar(250) DEFAULT NULL,
  `jsonPosicionamientoPlano` text DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codSector`),
  KEY `codFaseTres` (`codFaseTres`,`codProyecto`,`codAvaGrafico`),
  CONSTRAINT `avagra_sectores_ibfk_1` FOREIGN KEY (`codFaseTres`, `codProyecto`, `codAvaGrafico`) REFERENCES `avagra_fasetres` (`codFaseTres`, `codProyecto`, `codAvaGrafico`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_sectoresxpisos
-- ----------------------------------------------------------------
CREATE TABLE `avagra_sectoresxpisos` (
  `codSectorxPiso` bigint(20) NOT NULL AUTO_INCREMENT,
  `codPiso` bigint(20) NOT NULL,
  `codSector` bigint(20) NOT NULL,
  `desNombre` varchar(250) DEFAULT NULL,
  `desDescripcion` varchar(250) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `numPorcentajeCompletados` decimal(5,2) DEFAULT NULL,
  `numPorcentajeAprobadosCalidad` decimal(5,2) DEFAULT NULL,
  `jsonPosicionamientoPlano` text DEFAULT NULL,
  `codUsuarioCreacion` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `codUsuarioModificacion` bigint(20) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`codSectorxPiso`),
  UNIQUE KEY `codSectorxPiso` (`codSectorxPiso`,`codPiso`,`codSector`),
  KEY `codPiso` (`codPiso`),
  KEY `codSector` (`codSector`),
  KEY `codEstado` (`codEstado`),
  CONSTRAINT `avagra_sectoresxpisos_ibfk_1` FOREIGN KEY (`codPiso`) REFERENCES `avagra_pisos` (`codPiso`),
  CONSTRAINT `avagra_sectoresxpisos_ibfk_2` FOREIGN KEY (`codSector`) REFERENCES `avagra_sectores` (`codSector`),
  CONSTRAINT `avagra_sectoresxpisos_ibfk_3` FOREIGN KEY (`codEstado`) REFERENCES `avagra_estados` (`codEstado`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_sentidohorario
-- ----------------------------------------------------------------
CREATE TABLE `avagra_sentidohorario` (
  `CodSentido` int(11) NOT NULL AUTO_INCREMENT,
  `DesSentido` varchar(150) DEFAULT NULL,
  `DesAbrev` varchar(50) DEFAULT NULL,
  `DesIcon` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CodSentido`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- TABLE: avagra_tipolado
-- ----------------------------------------------------------------
CREATE TABLE `avagra_tipolado` (
  `CodTipoLado` int(11) NOT NULL AUTO_INCREMENT,
  `DesLado` varchar(150) DEFAULT NULL,
  `DesAbrev` varchar(50) DEFAULT NULL,
  `DesIcon` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`CodTipoLado`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
-- CATALOGO: avagra_estados
-- ----------------------------------------------------------------
INSERT INTO `avagra_estados` VALUES (1,'Pendiente','FaseUno_Posiciones','#bebeb9','gris'),(2,'Completado','FaseUno_Posiciones','#6ecc77','verde claro'),(3,'Programado Sem. Actual','FaseUno_Posiciones','#0190dc','celeste'),(4,'No Aplica','FaseUno_Posiciones','#000000','negro'),(5,'Pendiente','FaseDos_Cuadros','#bebeb9','gris'),(6,'En proceso','FaseDos_Cuadros','#ffb601','amarillo'),(7,'Completado','FaseDos_Cuadros','#6ecc77','verde claro'),(8,'Aprobado por Calidad','FaseDos_Cuadros','#015c1e','verde oscuro'),(9,'Programado Sem. Actual','FaseDos_Cuadros','#0190dc','celeste'),(10,'No Aplica','FaseDos_Cuadros','#000000','negro'),(11,'Pendiente','FaseTres_ActividadesXSectores','#bebeb9','gris'),(12,'En proceso','FaseTres_ActividadesXSectores','#ffb601','amarillo'),(13,'Completado','FaseTres_ActividadesXSectores','#6ecc77','verde claro'),(14,'Aprobado por Calidad','FaseTres_ActividadesXSectores','#015c1e','verde oscuro'),(15,'Programado Sem. Actual','FaseTres_ActividadesXSectores','#0190dc','celeste'),(16,'No Aplica','FaseTres_ActividadesXSectores','#000000','negro');


-- ----------------------------------------------------------------
-- CATALOGO: avagra_forma
-- ----------------------------------------------------------------
INSERT INTO `avagra_forma` VALUES (1,'Rectangulo Vertical',NULL,NULL),(2,'Rectangulo Horizontal',NULL,NULL),(3,'Cuadrado',NULL,NULL);


-- ----------------------------------------------------------------
-- CATALOGO: avagra_sentidohorario
-- ----------------------------------------------------------------
INSERT INTO `avagra_sentidohorario` VALUES (1,'Horario',NULL,NULL),(2,'Antihorario',NULL,NULL);


-- ----------------------------------------------------------------
-- CATALOGO: avagra_tipolado
-- ----------------------------------------------------------------
INSERT INTO `avagra_tipolado` VALUES (1,'Superior',NULL,NULL),(2,'Inferior',NULL,NULL),(3,'Izquierda',NULL,NULL),(4,'Derecha',NULL,NULL);

