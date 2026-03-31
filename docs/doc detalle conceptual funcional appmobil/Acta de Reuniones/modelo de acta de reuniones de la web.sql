


CREATE TABLE `actreu_actareuniones` (
  `codProyecto` bigint(20) NOT NULL,
  `codActReu` bigint(20) NOT NULL AUTO_INCREMENT,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codActReu`),
  KEY `codProyecto` (`codProyecto`,`codActReu`),
  CONSTRAINT `fk_actreu_actareuniones_codProyecto` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



DROP TABLE IF EXISTS `actreu_integrantes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `actreu_integrantes` (
  `codProyecto` bigint(20) NOT NULL,
  `codActReu` bigint(20) NOT NULL,
  `codProyIntegrante` bigint(20) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  UNIQUE KEY `unique_actreu_actareuniones_1` (`codProyecto`,`codActReu`,`codProyIntegrante`),
  KEY `fk_actreu_integrantes_2` (`codProyIntegrante`),
  CONSTRAINT `fk_actreu_integrantes_1` FOREIGN KEY (`codProyecto`, `codActReu`) REFERENCES `actreu_actareuniones` (`codProyecto`, `codActReu`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_actreu_integrantes_2` FOREIGN KEY (`codProyIntegrante`) REFERENCES `proy_integrantes` (`codProyIntegrante`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;



/* a nivel de proyectos se pude alimentar una tabla maestra de  grupos de acuerdos, aqui lo alimentamos */
CREATE TABLE `actreu_grupoacuerdo` (
  `codActReuGrupoAcuerdo` int(11) NOT NULL AUTO_INCREMENT,
  `desGrupoAcuerdo` varchar(150) DEFAULT NULL,
  `desColorGrupoAcuerdo` varchar(50) DEFAULT NULL,
  `codOptionalArea` int(11) DEFAULT NULL,
  `codProyecto` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`codActReuGrupoAcuerdo`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


 /* Tabla donde se crean las categorias de reuniones , ejem. Reu. Contabilidad, Reu. Finanzas , Reo. Administracion*/

CREATE TABLE `actreu_categoria` (
  `codProyecto` bigint(20) NOT NULL,
  `codActReu` bigint(20) NOT NULL,
  `codActReuCategoria` bigint(20) NOT NULL AUTO_INCREMENT,
  `desNombreCategoria` varchar(100) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  PRIMARY KEY (`codActReuCategoria`),
  KEY `fk_actreu_categoria_1` (`codProyecto`,`codActReu`),
  CONSTRAINT `fk_actreu_categoria_1` FOREIGN KEY (`codProyecto`, `codActReu`) REFERENCES `actreu_actareuniones` (`codProyecto`, `codActReu`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

 /* Tabla donde se crean las ubcategorias , puedes tener dentro de cada una de ellas , reu. Semanales , reu diarias, reu quincelanes , etc.*/

CREATE TABLE `actreu_subcategoria` (
  `codActReuSubCategoria` bigint(20) NOT NULL AUTO_INCREMENT,
  `codProyecto` bigint(20) NOT NULL,
  `codActReu` bigint(20) NOT NULL,
  `codActReuCategoria` bigint(20) NOT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `desNombreSubCategoria` varchar(100) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codActReuSubCategoria`),
  KEY `fk_actreu_subcategoria_1` (`codProyecto`,`codActReu`,`codActReuCategoria`),
  CONSTRAINT `fk_actreu_subcategoria_1` FOREIGN KEY (`codProyecto`, `codActReu`, `codActReuCategoria`) REFERENCES `actreu_categoria` (`codProyecto`, `codActReu`, `codActReuCategoria`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


/* Los participantes estan a nivel de subcategoria , es para que tu elijas los participantes que estaran en esa subcategoria */

CREATE TABLE `actreu_participantes` (
  `codActReuParticipante` bigint(20) NOT NULL AUTO_INCREMENT,
  `desNombre` varchar(150) DEFAULT NULL,
  `codArea` varchar(150) DEFAULT NULL,
  `desCorreoElectronico` varchar(100) DEFAULT NULL,
  `idUsuarioParticipante` bigint(20) DEFAULT NULL,
  `codProyIntegrante` bigint(20) DEFAULT NULL,
  `codActReuSubCategoria` bigint(20) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `flgParticipanteInvitado` bit(1) NOT NULL DEFAULT b'0',
  `codEstado` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`codActReuParticipante`),
  KEY `fk_actreu_participantes_1` (`codActReuSubCategoria`),
  CONSTRAINT `fk_actreu_participantes_1` FOREIGN KEY (`codActReuSubCategoria`) REFERENCES `actreu_subcategoria` (`codActReuSubCategoria`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=162 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;




/* Tabla de reuniones , por cada sub categoria hay reuniones, se peuden programar reuniones , pero hay que entender
que todas esas reuniones pertenecen a esa subcategoria. Estas reuniones se procede a cerrar manualmente 
cuando concluye la sesion en un eveno que se conoce como cierre de acta*/

CREATE TABLE `actreu_reuniones` (
  `codActReuReuniones` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActReuSubCategoria` bigint(20) DEFAULT NULL,
  `desNombre` varchar(250) DEFAULT NULL,
  `dayFechaReunion` datetime DEFAULT NULL,
  `dayFechaCierre` datetime DEFAULT NULL,
  `horHoraInicio` char(18) DEFAULT NULL,
  `horHoraFin` char(18) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `desLinkActaReunion` varchar(250) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  `groupedActReu` text DEFAULT NULL,
  `desNombreArchivoActaGenerada` varchar(100) DEFAULT NULL,
  `desNombreArchivoActaGeneradaFirmada` varchar(120) DEFAULT NULL,
  `desUrlDireccionActaGenerada` varchar(100) DEFAULT NULL,
  `desUrlDireccionActaGeneradaFirmada` varchar(120) DEFAULT NULL,
  `ordenGruposAcuerdo` text DEFAULT NULL,
  `ordenGruposAcuerdoAnteriores` text DEFAULT NULL,
  PRIMARY KEY (`codActReuReuniones`),
  KEY `fk_actreu_reuniones_1` (`codActReuSubCategoria`),
  CONSTRAINT `fk_actreu_reuniones_1` FOREIGN KEY (`codActReuSubCategoria`) REFERENCES `actreu_subcategoria` (`codActReuSubCategoria`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=333 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;





/* Esta es la tabla de acuerdos por cada reunion se van a llenar acuerdos , estos acuerdos  
tiene una fecha y fecha de vencimiento , se llenan todas las reuniones , y luego todas las 
reu. se hacen sseguimientos de esta . */

CREATE TABLE `actreu_acuerdos` (
  `codActReuAcuerdos` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActReuReuniones` bigint(20) DEFAULT NULL,
  `desAcuerdo` varchar(250) DEFAULT NULL,
  `dayFechaAcuerdo` datetime DEFAULT NULL,
  `dayFechaAplazo` datetime DEFAULT NULL,
  `dayFechaLevantamiento` datetime DEFAULT NULL,
  `numAplazos` int(11) DEFAULT NULL,  /* aca se contabilizan todos los aplazos que se tuvieron */
  `idUsuarioResponsable` bigint(20) DEFAULT NULL, /* aca se guarda el id del responsable  , este viene de la tabla  */
  `codEstado` int(11) DEFAULT NULL, 
  `numOrden` char(18) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  `codGrupoAcuerdo` int(11) DEFAULT NULL,
  `numOrdenAnteriores` int(11) DEFAULT NULL,
  PRIMARY KEY (`codActReuAcuerdos`),
  KEY `fk_actreu_acuerdos_1` (`codActReuReuniones`),
  KEY `R_63` (`codGrupoAcuerdo`),
  CONSTRAINT `R_63` FOREIGN KEY (`codGrupoAcuerdo`) REFERENCES `actreu_grupoacuerdo` (`codActReuGrupoAcuerdo`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_actreu_acuerdos_1` FOREIGN KEY (`codActReuReuniones`) REFERENCES `actreu_reuniones` (`codActReuReuniones`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=579 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/* cuando una reunion acaba   se genera una foto , con todos los acuerdos creados en ese dia , y los acuerdos pendientes  , osea los que no estan 
 completados y se guarda una foto de como quedo en esa fecha los acuerdos .*/

CREATE TABLE `actreu_acuerdosfoto` (
  `codActReuAcuerdosFoto` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActReuAcuerdos` bigint(20) DEFAULT NULL,
  `codActReuReuniones` bigint(20) DEFAULT NULL,
  `desAcuerdo` varchar(250) DEFAULT NULL,
  `dayFechaAcuerdo` datetime DEFAULT NULL,
  `dayFechaAplazo` datetime DEFAULT NULL,
  `dayFechaLevantamiento` datetime DEFAULT NULL,
  `numAplazos` int(11) DEFAULT NULL,
  `idUsuarioResponsable` bigint(20) DEFAULT NULL,
  `codGrupoAcuerdo` int(11) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `numOrden` char(18) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codActReuAcuerdosFoto`),
  KEY `fk_actreu_acuerdosfoto_1` (`codActReuReuniones`),
  KEY `fk_actreu_acuerdosfoto_2` (`codGrupoAcuerdo`),
  CONSTRAINT `fk_actreu_acuerdosfoto_1` FOREIGN KEY (`codActReuReuniones`) REFERENCES `actreu_reuniones` (`codActReuReuniones`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_actreu_acuerdosfoto_2` FOREIGN KEY (`codGrupoAcuerdo`) REFERENCES `actreu_grupoacuerdo` (`codActReuGrupoAcuerdo`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=5243 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* Puedes agregar comentarios  por cada acuerdo , osea puedes generar o abrir un debate por cada acuerdo 
   siempre el acuerdo todavia no este finalizado  
*/


CREATE TABLE `actreu_comentarios_acuerdo` (
  `codComentario` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActReuAcuerdos` bigint(20) NOT NULL,
  `codComentarioPadre` bigint(20) DEFAULT NULL,
  `idUsuario` bigint(20) NOT NULL,
  `desMensaje` text NOT NULL,
  `dayFechaComentario` datetime DEFAULT current_timestamp(),
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codComentario`),
  KEY `fk_comentario_acuerdo` (`codActReuAcuerdos`),
  KEY `fk_comentario_padre` (`codComentarioPadre`),
  CONSTRAINT `fk_comentario_acuerdo` FOREIGN KEY (`codActReuAcuerdos`) REFERENCES `actreu_acuerdos` (`codActReuAcuerdos`) ON DELETE CASCADE,
  CONSTRAINT `fk_comentario_padre` FOREIGN KEY (`codComentarioPadre`) REFERENCES `actreu_comentarios_acuerdo` (`codComentario`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*  
Al entrar a la reunion se debe de pasar asistencia , 
aqui marcamos la asistencia del equipo a la sesion */


CREATE TABLE `actreu_asistencias` (
  `codActReuAsistencia` bigint(20) NOT NULL AUTO_INCREMENT,
  `codActReuReuniones` bigint(20) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `desNombre` varchar(150) DEFAULT NULL,
  `desCorreoElectronico` varchar(100) DEFAULT NULL,
  `idUsuarioParticipante` bigint(20) DEFAULT NULL,
  `codProyIntegrante` bigint(20) DEFAULT NULL,
  `codActReuParticipante` bigint(20) DEFAULT NULL,
  `desJustificacion` text DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(100) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codActReuAsistencia`),
  KEY `fk_actreu_asistencias_1` (`codActReuReuniones`),
  KEY `fk_actreu_asistencias_2` (`codActReuParticipante`),
  CONSTRAINT `fk_actreu_asistencias_1` FOREIGN KEY (`codActReuReuniones`) REFERENCES `actreu_reuniones` (`codActReuReuniones`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_actreu_asistencias_2` FOREIGN KEY (`codActReuParticipante`) REFERENCES `actreu_participantes` (`codActReuParticipante`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=658 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;











