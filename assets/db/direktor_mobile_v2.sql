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

-- =========================================================
-- 3. ANALYSIS RESTRICTIONS - CATALOGS
-- =========================================================

CREATE TABLE IF NOT EXISTS anares_front (
    codAnaResFrente INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codAnaRes INTEGER,
    desAnaResFrente TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_phase (
    codAnaResFase INTEGER PRIMARY KEY,
    codAnaResFrente INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    codAnaRes INTEGER,
    desAnaResFase TEXT,
    bgColor TEXT,
    updated_at TEXT,
    FOREIGN KEY (codAnaResFrente) REFERENCES anares_front(codAnaResFrente) ON DELETE CASCADE,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anares_type (
    codTipoRestriccion INTEGER PRIMARY KEY,
    desTipoRestriccion TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS anares_area (
    codAnaresArea INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codArea INTEGER,
    desArea TEXT,
    bgColor TEXT,
    updated_at TEXT,
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
-- 4. ANALYSIS RESTRICTIONS
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
    desEstadoActividad TEXT,
    colorEstado TEXT,
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
    FOREIGN KEY (codTipoRestriccion) REFERENCES anares_type(codTipoRestriccion) ON DELETE SET NULL
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
-- 5. MEETINGS
-- =========================================================

CREATE TABLE IF NOT EXISTS meetings_meeting (
    codActReuReuniones INTEGER PRIMARY KEY,
    codProyecto INTEGER NOT NULL,
    codActReu INTEGER,
    codActReuCategoria INTEGER,
    codActReuSubCategoria INTEGER,
    desCategoria TEXT,
    desSubCategoria TEXT,
    desNombre TEXT,
    dayFechaReunion TEXT,
    dayFechaCierre TEXT,
    horHoraInicio TEXT,
    horHoraFin TEXT,
    codEstado TEXT,
    desEstado TEXT,
    desLinkActaReunion TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meetings_participant (
    codActReuParticipante INTEGER PRIMARY KEY,
    codActReuSubCategoria INTEGER,
    codProyecto INTEGER NOT NULL,
    idUsuarioParticipante INTEGER,
    codProyIntegrante INTEGER,
    desNombre TEXT,
    desCorreoElectronico TEXT,
    codArea TEXT,
    flgParticipanteInvitado INTEGER NOT NULL DEFAULT 0,
    codEstado INTEGER,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meetings_agreement (
    codActReuAcuerdos INTEGER PRIMARY KEY,
    codActReuReuniones INTEGER NOT NULL,
    codProyecto INTEGER NOT NULL,
    desAcuerdo TEXT,
    dayFechaAcuerdo TEXT,
    dayFechaAplazo TEXT,
    dayFechaLevantamiento TEXT,
    numAplazos INTEGER,
    idUsuarioResponsable INTEGER,
    desResponsable TEXT,
    codEstado TEXT,
    desEstado TEXT,
    codGrupoAcuerdo INTEGER,
    desGrupoAcuerdo TEXT,
    desColorGrupoAcuerdo TEXT,
    is_overdue INTEGER NOT NULL DEFAULT 0,
    is_pending INTEGER NOT NULL DEFAULT 0,
    is_completed INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
    FOREIGN KEY (codActReuReuniones) REFERENCES meetings_meeting(codActReuReuniones) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meetings_comment (
    codComentario INTEGER PRIMARY KEY,
    codActReuAcuerdos INTEGER NOT NULL,
    codComentarioPadre INTEGER,
    idUsuario INTEGER,
    desMensaje TEXT NOT NULL,
    dayFechaComentario TEXT,
    updated_at TEXT,
    FOREIGN KEY (codActReuAcuerdos) REFERENCES meetings_agreement(codActReuAcuerdos) ON DELETE CASCADE,
    FOREIGN KEY (codComentarioPadre) REFERENCES meetings_comment(codComentario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meetings_summary (
    codProyecto INTEGER PRIMARY KEY,
    overdueAgreementsCount INTEGER NOT NULL DEFAULT 0,
    pendingAgreementsCount INTEGER NOT NULL DEFAULT 0,
    nextMeetingDate TEXT,
    updated_at TEXT,
    FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
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

INSERT OR IGNORE INTO app_settings (key, value, updated_at)
VALUES
('db_version', '1', datetime('now')),
('last_sync_at', NULL, NULL),
('current_project_id', NULL, NULL);
