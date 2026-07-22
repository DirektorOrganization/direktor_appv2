PRAGMA foreign_keys = ON;

-- =========================================================
-- DIREKTOR MOBILE V2 - SQLITE LOCAL MODEL
-- =========================================================

-- =========================================================
-- 1. AUTH / SESSION / USER
-- =========================================================

CREATE TABLE IF NOT EXISTS auth_session (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT,
    refresh_token TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    last_login_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS auth_user (
    id INTEGER PRIMARY KEY,
    name TEXT,
    lastname TEXT,
    email TEXT,
    password TEXT,
    celular TEXT,
    nombreempresa TEXT,
    codCargo INTEGER,
    flgSuperAdmin INTEGER NOT NULL DEFAULT 0,
    codEstadoUsuarioxSuscripcion INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS auth_active_subscription (
    cod_Empresa INTEGER NOT NULL,
    codSuscripcion INTEGER NOT NULL,
    dayFechaInicio TEXT,
    dayFechaFin TEXT,
    dayFechaCancelada TEXT,
    codEstado INTEGER,
    codVendedor INTEGER,
    numProyectosGratisUsados INTEGER,
    numProyectosUsados INTEGER,
    numLimiteProyectos INTEGER,
    numAlertasWspUsados INTEGER,
    numAlertasWspGratisUsados INTEGER,
    desCorreoContacto TEXT,
    flgAutoAprobarUsuarios INTEGER NOT NULL DEFAULT 0,
    codPerfilPredeterminado INTEGER,
    codMoneda INTEGER,
    dayFechaCreacion TEXT,
    dayFechaModificacion TEXT,
    codUsuarioCreacion INTEGER,
    codUsuarioModificacion INTEGER,
    updated_at TEXT,
    PRIMARY KEY (cod_Empresa, codSuscripcion)
);

CREATE TABLE IF NOT EXISTS auth_active_subscription_module (
    cod_Empresa INTEGER NOT NULL,
    codSuscripcion INTEGER NOT NULL,
    codModulo INTEGER NOT NULL,
    desModulo TEXT,
    desModuloAbrev TEXT,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    dayFechaModificacion TEXT,
    codUsuarioCreacion INTEGER,
    codUsuarioModificacion INTEGER,
    updated_at TEXT,
    PRIMARY KEY (cod_Empresa, codSuscripcion, codModulo)
);

CREATE TABLE IF NOT EXISTS auth_active_subscription_service (
    codServicioSuscripcion INTEGER NOT NULL,
    cod_Empresa INTEGER NOT NULL,
    codSuscripcion INTEGER NOT NULL,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    dayFechaModificacion TEXT,
    codUsuarioCreacion INTEGER,
    codUsuarioModificacion INTEGER,
    desServicio TEXT,
    desAbrev TEXT,
    desDescripcion TEXT,
    desIcono TEXT,
    desColor TEXT,
    updated_at TEXT,
    PRIMARY KEY (codServicioSuscripcion, cod_Empresa, codSuscripcion)
);

CREATE TABLE IF NOT EXISTS subscription_customization_scope (
    cod_Empresa INTEGER,
    codSuscripcion INTEGER,
    moduloAbrev TEXT NOT NULL,
    elementoControlAbrev TEXT NOT NULL,
    codModulo INTEGER,
    desModuloAbrev TEXT,
    moduloNombreOriginal TEXT,
    moduloNombreVisible TEXT,
    moduloCodEstado INTEGER,
    codElemControlxSuscripcion INTEGER,
    codElementoControl INTEGER,
    elementoDesAbrev TEXT,
    elementoNombreOriginal TEXT,
    elementoNombreVisible TEXT,
    elementoCodEstado INTEGER,
    elementoVisible INTEGER NOT NULL DEFAULT 1,
    updated_at TEXT,
    PRIMARY KEY (elementoControlAbrev)
);

CREATE TABLE IF NOT EXISTS subscription_customization_column (
    codColumna INTEGER NOT NULL,
    elementoControlAbrev TEXT NOT NULL,
    codElemControlxSuscripcion INTEGER,
    desColumna TEXT NOT NULL,
    desNombre TEXT,
    desNombrePersonalizado TEXT,
    flgActivo INTEGER NOT NULL DEFAULT 1,
    flgDefault INTEGER NOT NULL DEFAULT 0,
    nombreVisible TEXT,
    updated_at TEXT,
    PRIMARY KEY (codColumna, elementoControlAbrev)
);

CREATE TABLE IF NOT EXISTS subscription_customization_status (
    codEstadoxSuscripcion INTEGER PRIMARY KEY,
    elementoControlAbrev TEXT NOT NULL,
    codElemControlxSuscripcion INTEGER,
    codEstadoControl INTEGER,
    desEstado TEXT,
    iconColor TEXT,
    flgDefault INTEGER NOT NULL DEFAULT 0,
    flgActivo INTEGER NOT NULL DEFAULT 1,
    desEstadoOriginal TEXT,
    codEstado TEXT,
    iconColorOriginal TEXT,
    nombreVisible TEXT,
    updated_at TEXT
);

-- =========================================================
-- 2. PROJECTS
-- =========================================================

CREATE TABLE IF NOT EXISTS projects_project (
    codProyecto INTEGER PRIMARY KEY,
    desNombreProyecto TEXT,
    codEstado INTEGER,
    codEmpresa INTEGER,
    desEmpresa TEXT,
    codTipoProyecto INTEGER,
    desTipoProyecto TEXT,
    codMoneda INTEGER,
    desMoneda TEXT,
    desSimboloMoneda TEXT,
    codUbigeo INTEGER,
    desUbigeo TEXT,
    desDireccion TEXT,
    dayFechaInicio TEXT,
    is_last_selected INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS project_user_profile (
    codProyecto INTEGER PRIMARY KEY,
    codPerfilEmpresa INTEGER,
    desPerfilEmpresa TEXT,
    desDescripcionPerfilEmpresa TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project_user_profile_permission (
    codProyecto INTEGER NOT NULL,
    codPerfilEmpresa INTEGER,
    codPermisoUsuario INTEGER,
    codModulo INTEGER NOT NULL,
    desPermisoUsuario TEXT,
    desDescripcionPermiso TEXT,
    desModulo TEXT,
    desModuloAbrev TEXT,
    updated_at TEXT,
    PRIMARY KEY (codProyecto, codModulo),
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS projects_member (
    codProyIntegrante INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    user_id INTEGER,
    codArea INTEGER,
    desArea TEXT,
    codRolIntegrante INTEGER,
    desRolIntegrante TEXT,
    codEstadoInvitacion TEXT,
    desCorreo TEXT,
    numCelular TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS projects_area_member (
    codArea INTEGER PRIMARY KEY,
    desArea TEXT

);


-- =========================================================
-- 3. ANALYSIS RESTRICTIONS
-- =========================================================

-- =========================================================
-- 3.1. CATALOGS
-- =========================================================

CREATE TABLE IF NOT EXISTS anares_analysis (
    codAnaRes INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_front (
    codAnaResFrente INTEGER PRIMARY KEY,
    codAnaResFrenteRemoto INTEGER,
    codProyecto INTEGER NOT NULL,
    codAnaRes INTEGER,
    desAnaResFrente TEXT,
    codEstado INTEGER NOT NULL DEFAULT 1,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_phase (
    codAnaResFase INTEGER PRIMARY KEY,
    codAnaResFaseRemoto INTEGER,
    codAnaResFrente INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    codAnaRes INTEGER,
    desAnaResFase TEXT,
    bgColor TEXT,
    codEstado INTEGER NOT NULL DEFAULT 1,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    FOREIGN KEY (codAnaResFrente) REFERENCES anares_front(codAnaResFrente) ON DELETE CASCADE,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_type (
    codTipoRestriccionxEmpresa INTEGER PRIMARY KEY,
    cod_Empresa INTEGER,
    codTipoRestricciones INTEGER,
    desTipoRestriccion TEXT,
    flgIsDefault INTEGER NOT NULL DEFAULT 0,
    codEstado INTEGER NOT NULL DEFAULT 1,
    dayFechaCreacion TEXT,
    dayFechaModificacion TEXT,
    codUsuarioCreacion INTEGER,
    codUsuarioModificacion INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS anares_area (
    codAnaresArea INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codArea INTEGER,
    desArea TEXT,
    cod_Empresa INTEGER,
    bgColor TEXT,
    updated_at TEXT,
    is_codAnaresAreaLocal INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_status (
    codEstado TEXT PRIMARY KEY,
    desEstado TEXT,
    iconColor TEXT,
    codModulo INTEGER,
    codElementoControl INTEGER,
    updated_at TEXT
);

-- =========================================================
-- 3.2. MAIN TABLES
-- =========================================================

CREATE TABLE IF NOT EXISTS anares_restriction (
    codAnaResActividad INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codAnaRes INTEGER,
    codAnaResFrente INTEGER,
    codAnaResFase INTEGER,
    desFrente TEXT,
    desFase TEXT,
    desActividad TEXT,
    desRestriccion TEXT,
    codTipoRestriccion INTEGER,
    desTipoRestriccion TEXT,
    dayFechaRequerida TEXT,
    dayFechaConciliada TEXT,
    dayFechaLevantamiento TEXT,
    idUsuarioResponsable INTEGER,
    desResponsable TEXT,
    codEstadoActividad TEXT,
    codEstadoxSuscripcion INTEGER,
    desEstadoActividad TEXT,
    colorEstado TEXT,
    codAnaresArea TEXT,
    codUsuarioSolicitante TEXT,
    desSolicitante TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    is_overdue INTEGER NOT NULL DEFAULT 0,
    is_due_today INTEGER NOT NULL DEFAULT 0,
    is_pending INTEGER NOT NULL DEFAULT 0,
    is_in_progress INTEGER NOT NULL DEFAULT 0,
    priority_order INTEGER NOT NULL DEFAULT 999,
    dayFechaCreacion TEXT,
    dayFechaModificacion TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codAnaResFrente) REFERENCES anares_front(codAnaResFrente) ON DELETE SET NULL,
    FOREIGN KEY (codAnaResFase) REFERENCES anares_phase(codAnaResFase) ON DELETE SET NULL,
    FOREIGN KEY (codTipoRestriccion) REFERENCES anares_type(codTipoRestriccionxEmpresa) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS anares_summary (
    codProyecto INTEGER PRIMARY KEY,
    totalRestrictions INTEGER NOT NULL DEFAULT 0,
    completedCount INTEGER NOT NULL DEFAULT 0,
    overdueCount INTEGER NOT NULL DEFAULT 0,
    inProgressCount INTEGER NOT NULL DEFAULT 0,
    pendingCount INTEGER NOT NULL DEFAULT 0,
    compliancePercent REAL NOT NULL DEFAULT 0,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

-- =========================================================
-- 4. ACTA DE REUNIONES (ACTREU) - MODELO COMPLETO
-- =========================================================

CREATE TABLE IF NOT EXISTS actreu_actareuniones (
    codActReu INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_categoria (
    codActReuCategoria INTEGER PRIMARY KEY,
    codActReuCategoriaRemoto INTEGER,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER NOT NULL,
    desNombreCategoria TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    codEstado INTEGER,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReu) REFERENCES actreu_actareuniones(codActReu) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_subcategoria (
    codActReuSubCategoria INTEGER PRIMARY KEY,
    codActReuSubCategoriaRemoto INTEGER,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER NOT NULL,
    codActReuCategoria INTEGER NOT NULL,
    codEstado INTEGER,
    desNombreSubCategoria TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReu) REFERENCES actreu_actareuniones(codActReu) ON DELETE CASCADE,
    FOREIGN KEY (codActReuCategoria) REFERENCES actreu_categoria(codActReuCategoria) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_reuniones (
    codActReuReuniones INTEGER PRIMARY KEY,
    codActReuReunionesRemoto INTEGER,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER NOT NULL,
    desNombre TEXT,
    dayFechaReunion TEXT,
    dayFechaCierre TEXT,
    horHoraInicio TEXT,
    horHoraFin TEXT,
    codEstado INTEGER,
    desLinkActaReunion TEXT,
    groupedActReu TEXT,
    desNombreArchivoActaGenerada TEXT,
    desNombreArchivoActaGeneradaFirmada TEXT,
    desUrlDireccionActaGenerada TEXT,
    desUrlDireccionActaGeneradaFirmada TEXT,
    ordenGruposAcuerdo TEXT,
    ordenGruposAcuerdoAnteriores TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuSubCategoria) REFERENCES actreu_subcategoria(codActReuSubCategoria) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_participantes (
    codActReuParticipante INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER NOT NULL,
    desNombre TEXT,
    codArea TEXT,
    desCorreoElectronico TEXT,
    idUsuarioParticipante INTEGER,
    codProyIntegrante INTEGER,
    flgParticipanteInvitado INTEGER NOT NULL DEFAULT 0,
    codEstado INTEGER NOT NULL DEFAULT 1,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuSubCategoria) REFERENCES actreu_subcategoria(codActReuSubCategoria) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_grupoacuerdo (
    codActReuGrupoAcuerdo INTEGER PRIMARY KEY,
    codActReuGrupoAcuerdoRemoto INTEGER,
    codProyecto INTEGER,
    desGrupoAcuerdo TEXT,
    desColorGrupoAcuerdo TEXT,
    codOptionalArea INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_acuerdos (
    codActReuAcuerdos INTEGER PRIMARY KEY,
    codActReuAcuerdosRemoto INTEGER,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER,
    codActReuReuniones INTEGER NOT NULL,
    desAcuerdo TEXT,
    dayFechaAcuerdo TEXT,
    dayFechaAplazo TEXT,
    dayFechaLevantamiento TEXT,
    numAplazos INTEGER,
    idUsuarioResponsable INTEGER,
    codEstado INTEGER,
    codEstadoxSuscripcion INTEGER,
    numOrden TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    codGrupoAcuerdo INTEGER,
    numOrdenAnteriores INTEGER,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuReuniones) REFERENCES actreu_reuniones(codActReuReuniones) ON DELETE CASCADE,
    FOREIGN KEY (codGrupoAcuerdo) REFERENCES actreu_grupoacuerdo(codActReuGrupoAcuerdo) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS actreu_acuerdosfoto (
    codActReuAcuerdosFoto INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER,
    codActReuAcuerdos INTEGER,
    codActReuReuniones INTEGER,
    desAcuerdo TEXT,
    dayFechaAcuerdo TEXT,
    dayFechaAplazo TEXT,
    dayFechaLevantamiento TEXT,
    numAplazos INTEGER,
    idUsuarioResponsable INTEGER,
    codGrupoAcuerdo INTEGER,
    codEstado INTEGER,
    codEstadoxSuscripcion INTEGER,
    numOrden TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuReuniones) REFERENCES actreu_reuniones(codActReuReuniones) ON DELETE CASCADE,
    FOREIGN KEY (codGrupoAcuerdo) REFERENCES actreu_grupoacuerdo(codActReuGrupoAcuerdo) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS actreu_comentarios_acuerdo (
    codComentario INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER,
    codActReuReuniones INTEGER,
    codActReuAcuerdos INTEGER NOT NULL,
    codComentarioPadre INTEGER,
    idUsuario INTEGER,
    desMensaje TEXT NOT NULL,
    dayFechaComentario TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuAcuerdos) REFERENCES actreu_acuerdos(codActReuAcuerdos) ON DELETE CASCADE,
    FOREIGN KEY (codComentarioPadre) REFERENCES actreu_comentarios_acuerdo(codComentario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS actreu_asistencias (
    codActReuAsistencia INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER,
    codActReuReuniones INTEGER NOT NULL,
    codEstado INTEGER,
    desNombre TEXT,
    desCorreoElectronico TEXT,
    idUsuarioParticipante INTEGER,
    codProyIntegrante INTEGER,
    codActReuParticipante INTEGER,
    desJustificacion TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuReuniones) REFERENCES actreu_reuniones(codActReuReuniones) ON DELETE CASCADE,
    FOREIGN KEY (codActReuParticipante) REFERENCES actreu_participantes(codActReuParticipante) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS actreu_integrantes (
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER NOT NULL,
    codProyIntegrante INTEGER NOT NULL,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (codProyecto, codActReu, codProyIntegrante),
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReu) REFERENCES actreu_actareuniones(codActReu) ON DELETE CASCADE,
    FOREIGN KEY (codProyIntegrante) REFERENCES projects_member(codProyIntegrante) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS actreu_summary (
    codProyecto INTEGER PRIMARY KEY,
    totalSessions INTEGER NOT NULL DEFAULT 0,
    scheduledSessions INTEGER NOT NULL DEFAULT 0,
    activeSessions INTEGER NOT NULL DEFAULT 0,
    overdueAgreements INTEGER NOT NULL DEFAULT 0,
    pendingAgreements INTEGER NOT NULL DEFAULT 0,
    informativeAgreements INTEGER NOT NULL DEFAULT 0,
    categoriesCount INTEGER NOT NULL DEFAULT 0,
    subcategoriesCount INTEGER NOT NULL DEFAULT 0,
    compliancePercent REAL NOT NULL DEFAULT 0,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

-- Estados maestros de ACTREU
CREATE TABLE IF NOT EXISTS actreu_status_categoria (
    codEstado INTEGER PRIMARY KEY,
    desEstado TEXT NOT NULL,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS actreu_status_subcategoria (
    codEstado INTEGER PRIMARY KEY,
    desEstado TEXT NOT NULL,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS actreu_status_reuniones (
    codEstado INTEGER PRIMARY KEY,
    desEstado TEXT NOT NULL,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS actreu_status_acuerdos (
    codEstado INTEGER PRIMARY KEY,
    desEstado TEXT NOT NULL,
    updated_at TEXT,
    deleted INTEGER NOT NULL DEFAULT 0
);

-- =========================================================
-- 5. CONTROL DE HITOS
-- =========================================================

CREATE TABLE IF NOT EXISTS conhit_tipohito (
    codTipoHito INTEGER PRIMARY KEY,
    desTipoHito TEXT NOT NULL,
    orden INTEGER,
    codEstado INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS conhit_tipoclasificacion (
    codTipoClasificacion INTEGER PRIMARY KEY,
    desTipoClasificacion TEXT NOT NULL,
    orden INTEGER,
    codEstado INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS conhit_statusinterno (
    codEstado TEXT PRIMARY KEY,
    desEstado TEXT NOT NULL,
    desColor TEXT,
    desIcono TEXT,
    orden INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS conhit_statuscontractual (
    codEstado TEXT PRIMARY KEY,
    desEstado TEXT NOT NULL,
    desColor TEXT,
    desIcono TEXT,
    orden INTEGER,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS conhit_controlhitos (
    codConHit INTEGER PRIMARY KEY,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    codProyecto INTEGER NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conhit_general (
    codConHitGeneral INTEGER PRIMARY KEY,
    codConHitGeneralRemoto INTEGER,
    codConHit INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    numDiasPlazoTotal INTEGER,
    mntTotal REAL,
    numDias INTEGER,
    codEstado INTEGER,
    dayFechaInicioContractual TEXT,
    flgAplicaHitoGeneral INTEGER NOT NULL DEFAULT 0,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codConHit) REFERENCES conhit_controlhitos(codConHit) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conhit_detallehitos (
    codConHitDetalleHitos INTEGER PRIMARY KEY,
    codConHitDetalleHitosRemoto INTEGER,
    codConHit INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    codConHitGeneral INTEGER NOT NULL,
    NumOrden INTEGER,
    desDescripcion TEXT,
    codTipoHito INTEGER,
    codTipoClasificacion INTEGER,
    numplazo INTEGER,
    porPenalidad REAL,
    dayFechaContractual TEXT,
    dayFechaMeta TEXT,
    numCantAmpContractual INTEGER,
    numCantAmpMeta INTEGER,
    dayFechaReal TEXT,
    desLinkDocuCierre TEXT,
    codEstadoContractual INTEGER,
    codEstadoInternos TEXT,
    mntPealidad REAL DEFAULT 0,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    dayFechaContractualAmp TEXT,
    dayFechaMetaAmp TEXT,
    codEstado INTEGER NOT NULL DEFAULT 1,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codConHit) REFERENCES conhit_controlhitos(codConHit) ON DELETE CASCADE,
    FOREIGN KEY (codConHitGeneral) REFERENCES conhit_general(codConHitGeneral) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conhit_documentos (
    codConhitDocumentos INTEGER PRIMARY KEY,
    codConHit TEXT NOT NULL,
    desNombreArchivo TEXT NOT NULL,
    desRutaArchivo TEXT NOT NULL,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModifcacion TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS conhit_archivosfechareal (
    codConhitArchivosFechaReal INTEGER PRIMARY KEY,
    codConhitArchivosFechaRealRemoto INTEGER,
    codConHitDetalleHitos INTEGER,
    desNombreArchivo TEXT,
    desRutaArchivo TEXT NOT NULL,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModifcacion TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codConHitDetalleHitos) REFERENCES conhit_detallehitos(codConHitDetalleHitos) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conhit_integrantes (
    codConHit INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    codEstado INTEGER,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    codProyIntegrante INTEGER,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    PRIMARY KEY (codConHit, codProyecto, codProyIntegrante),
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codConHit) REFERENCES conhit_controlhitos(codConHit) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conthit_detallehitosamp (
    codConHitDetalleHitosAmp INTEGER PRIMARY KEY,
    codConHitDetalleHitosAmpRemoto INTEGER,
    codConHitDetalleHitos INTEGER NOT NULL,
    desMotivo TEXT,
    dayFechaMeta TEXT,
    dayFechaContractual TEXT,
    desLinklDocuAmp TEXT,
    dayFechaCreacion TEXT,
    desUsuarioCreacion TEXT,
    dayFechaModificacion TEXT,
    desUsuarioModificacion TEXT,
    desTipoFecha TEXT,
    codEstado INTEGER NOT NULL DEFAULT 1,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TEXT,
    FOREIGN KEY (codConHitDetalleHitos) REFERENCES conhit_detallehitos(codConHitDetalleHitos) ON DELETE CASCADE
);

-- =========================================================
-- 6. SYNC
-- =========================================================

CREATE TABLE IF NOT EXISTS sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation_type TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,
    result TEXT NOT NULL,
    message TEXT,
    created_at TEXT
);

-- =========================================================
-- 7. APP SETTINGS
-- =========================================================

CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TEXT
);

-- =========================================================
-- 8. INITIAL SETTINGS
-- =========================================================

INSERT OR IGNORE INTO actreu_status_categoria (codEstado, desEstado, updated_at, deleted)
VALUES
(1, 'Activo', datetime('now'), 0);

INSERT OR IGNORE INTO actreu_status_subcategoria (codEstado, desEstado, updated_at, deleted)
VALUES
(1, 'En Progreso', datetime('now'), 0),
(2, 'Finalizado', datetime('now'), 0);

INSERT OR IGNORE INTO actreu_status_reuniones (codEstado, desEstado, updated_at, deleted)
VALUES
(1, 'Programada', datetime('now'), 0),
(2, 'Finalizado', datetime('now'), 0),
(3, 'Retrasado', datetime('now'), 0);

INSERT OR IGNORE INTO actreu_status_acuerdos (codEstado, desEstado, updated_at, deleted)
VALUES
(1, 'En Progreso', datetime('now'), 0),
(2, 'Aplazado', datetime('now'), 0),
(3, 'Finalizado acuerdo', datetime('now'), 0),
(4, 'Atrasado', datetime('now'), 0),
(6, 'Informativo', datetime('now'), 0);

INSERT OR IGNORE INTO app_settings (key, value, updated_at)
VALUES
('db_version', '1', datetime('now')),
('last_sync_at', NULL, NULL),
('current_project_id', NULL, NULL);
