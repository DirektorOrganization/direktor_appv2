

DROP TABLE IF EXISTS `conhit_archivosfechareal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_archivosfechareal` (
  `codConhitArchivosFechaReal` bigint(20) NOT NULL AUTO_INCREMENT,
  `codConHitDetalleHitos` bigint(20) DEFAULT NULL,
  `desNombreArchivo` varchar(250) DEFAULT NULL,
  `desRutaArchivo` varchar(255) NOT NULL,
  `dayFechaCreacion` datetime DEFAULT current_timestamp(),
  `desUsuarioCreacion` varchar(250) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `desUsuarioModifcacion` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`codConhitArchivosFechaReal`),
  KEY `fk_conhit_archivosfechareal_detallehitos` (`codConHitDetalleHitos`),
  CONSTRAINT `fk_conhit_archivosfechareal_detallehitos` FOREIGN KEY (`codConHitDetalleHitos`) REFERENCES `conhit_detallehitos` (`codConHitDetalleHitos`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;




--
-- Table structure for table `conhit_controlhitos`
--

DROP TABLE IF EXISTS `conhit_controlhitos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_controlhitos` (
  `codConHit` bigint(20) NOT NULL AUTO_INCREMENT,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(150) DEFAULT NULL,
  `codProyecto` bigint(20) NOT NULL,
  PRIMARY KEY (`codConHit`),
  KEY `codProyecto` (`codProyecto`,`codConHit`),
  CONSTRAINT `fk_conhit_controlhitos_codproyecto` FOREIGN KEY (`codProyecto`) REFERENCES `proy_proyecto` (`codProyecto`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;




--
-- Table structure for table `conhit_detallehitos`
--

DROP TABLE IF EXISTS `conhit_detallehitos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_detallehitos` (
  `codConHitDetalleHitos` bigint(20) NOT NULL AUTO_INCREMENT,
  `codConHit` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `codConHitGeneral` bigint(20) NOT NULL,
  `NumOrden` int(11) DEFAULT NULL,
  `desDescripcion` varchar(150) DEFAULT NULL,
  `codTipoHito` int(11) DEFAULT NULL,
  `codTipoClasificacion` int(11) DEFAULT NULL,
  `numplazo` int(11) DEFAULT NULL,
  `porPenalidad` decimal(5,4) DEFAULT NULL,
  `dayFechaContractual` datetime DEFAULT NULL,
  `dayFechaMeta` datetime DEFAULT NULL,
  `numCantAmpContractual` int(11) DEFAULT NULL,
  `numCantAmpMeta` int(11) DEFAULT NULL,
  `dayFechaReal` datetime DEFAULT NULL,
  `desLinkDocuCierre` varchar(150) DEFAULT NULL,
  `codEstadoContractual` int(11) DEFAULT NULL,
  `codEstadoInternos` int(11) DEFAULT NULL,
  `mntPealidad` decimal(18,5) DEFAULT 0.00000,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(150) DEFAULT NULL,
  `dayFechaContractualAmp` datetime DEFAULT NULL,
  `dayFechaMetaAmp` datetime DEFAULT NULL,
  PRIMARY KEY (`codConHitDetalleHitos`)
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `conhit_documentos`
--

DROP TABLE IF EXISTS `conhit_documentos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_documentos` (
  `codConhitDocumentos` bigint(20) NOT NULL AUTO_INCREMENT,
  `codConHit` varchar(50) NOT NULL,
  `desNombreArchivo` varchar(255) NOT NULL,
  `desRutaArchivo` varchar(255) NOT NULL,
  `dayFechaCreacion` datetime NOT NULL DEFAULT current_timestamp(),
  `desUsuarioCreacion` varchar(100) NOT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `desUsuarioModifcacion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`codConhitDocumentos`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;





--
-- Table structure for table `conhit_general`
--

DROP TABLE IF EXISTS `conhit_general`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_general` (
  `codConHitGeneral` bigint(20) NOT NULL AUTO_INCREMENT,
  `codConHit` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(150) DEFAULT NULL,
  `numDiasPlazoTotal` int(11) DEFAULT NULL,
  `mntTotal` decimal(10,2) DEFAULT NULL,
  `numDias` int(11) DEFAULT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaInicioContractual` datetime DEFAULT NULL,
  PRIMARY KEY (`codConHitGeneral`),
  UNIQUE KEY `codConHit` (`codConHit`,`codProyecto`,`codConHitGeneral`),
  KEY `fk_conhit_general` (`codProyecto`,`codConHit`),
  CONSTRAINT `fk_conhit_general` FOREIGN KEY (`codProyecto`, `codConHit`) REFERENCES `conhit_controlhitos` (`codProyecto`, `codConHit`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `conhit_integrantes`
--

DROP TABLE IF EXISTS `conhit_integrantes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conhit_integrantes` (
  `codConHit` bigint(20) NOT NULL,
  `codProyecto` bigint(20) NOT NULL,
  `codEstado` int(11) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(150) DEFAULT NULL,
  `codProyIntegrante` bigint(20) DEFAULT NULL,
  UNIQUE KEY `codConHit` (`codConHit`,`codProyecto`,`codProyIntegrante`),
  KEY `fk_conhit_integrantes_1` (`codProyecto`,`codConHit`),
  KEY `fk_conhit_integrantes_2` (`codProyIntegrante`),
  CONSTRAINT `fk_conhit_integrantes_1` FOREIGN KEY (`codProyecto`, `codConHit`) REFERENCES `conhit_controlhitos` (`codProyecto`, `codConHit`),
  CONSTRAINT `fk_conhit_integrantes_2` FOREIGN KEY (`codProyIntegrante`) REFERENCES `proy_integrantes` (`codProyIntegrante`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;




--
-- Table structure for table `conthit_detallehitosamp`
--

DROP TABLE IF EXISTS `conthit_detallehitosamp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conthit_detallehitosamp` (
  `codConHitDetalleHitosAmp` bigint(20) NOT NULL AUTO_INCREMENT,
  `codConHitDetalleHitos` bigint(20) NOT NULL,
  `desMotivo` varchar(250) DEFAULT NULL,
  `dayFechaMeta` datetime DEFAULT NULL,
  `dayFechaContractual` datetime DEFAULT NULL,
  `desLinklDocuAmp` varchar(150) DEFAULT NULL,
  `dayFechaCreacion` datetime DEFAULT NULL,
  `desUsuarioCreacion` varchar(150) DEFAULT NULL,
  `dayFechaModificacion` datetime DEFAULT NULL,
  `desUsuarioModificacion` varchar(150) DEFAULT NULL,
  `desTipoFecha` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`codConHitDetalleHitosAmp`),
  UNIQUE KEY `codConHitDetalleHitos` (`codConHitDetalleHitos`,`codConHitDetalleHitosAmp`),
  CONSTRAINT `fk_conhit_detallehitosamp` FOREIGN KEY (`codConHitDetalleHitos`) REFERENCES `conhit_detallehitos` (`codConHitDetalleHitos`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


