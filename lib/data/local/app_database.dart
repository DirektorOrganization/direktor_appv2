import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../app/core/app_clock.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseFileName = 'direktor_mobile_v2.db';

  Database? _database;

  String _limaNowIso8601() => AppClock.nowIso8601InDefaultZone();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseFileName);

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _executeSchema(db);
        await _ensureAuthUserPasswordColumn(db);
        await _ensureAuthUserSubscriptionColumns(db);
        await _ensureRestrictionAreaStructures(db);
        await _ensureRestrictionTypeStructures(db);
        await _ensureControlHitosStructures(db);
        await _ensureActreuStructures(db);
        await _ensureAvanceGraficoStructures(db);
        await _ensureSubscriptionStructures(db);
        await _ensureSubscriptionCustomizationStructures(db);
        await _ensureModuleInsightsStructures(db);
        await _ensureInsightRuleConfigStructures(db);
        await _seed(db);
      },
      onOpen: (db) async {
        // Keep existing installs aligned with the latest SQLite schema additions.
        await _executeSchema(db);
        await _ensureAuthUserPasswordColumn(db);
        await _ensureAuthUserSubscriptionColumns(db);
        await _ensureRestrictionAreaStructures(db);
        await _ensureRestrictionTypeStructures(db);
        await _ensureControlHitosStructures(db);
        await _ensureActreuStructures(db);
        await _ensureAvanceGraficoStructures(db);
        await _ensureSubscriptionStructures(db);
        await _ensureSubscriptionCustomizationStructures(db);
        await _ensureModuleInsightsStructures(db);
        await _ensureInsightRuleConfigStructures(db);
        await _ensureHubStyleColumn(db);
        await _ensureHubIndicatorPrefs(db);
        await _ensureDefaultSettings(db, _limaNowIso8601());
      },
    );
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseFileName);
    final existing = _database;
    _database = null;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    await deleteDatabase(path);
  }

  Future<void> _executeSchema(Database db) async {
    final sql = await rootBundle.loadString('assets/db/direktor_mobile_v2.sql');
    final statements = sql
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty)
        .toList();

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _ensureAuthUserPasswordColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(auth_user)');
    final hasPassword = columns.any((column) => column['name'] == 'password');
    if (!hasPassword) {
      await db.execute('ALTER TABLE auth_user ADD COLUMN password TEXT');
    }
  }

  Future<void> _ensureHubStyleColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(auth_user)');
    final hasHubStyle = columns.any((c) => c['name'] == 'hub_style');
    if (!hasHubStyle) {
      await db.execute('ALTER TABLE auth_user ADD COLUMN hub_style TEXT');
    }
  }

  Future<void> _ensureAuthUserSubscriptionColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(auth_user)');
    final hasSuperAdmin = columns.any(
      (column) => column['name'] == 'flgSuperAdmin',
    );
    if (!hasSuperAdmin) {
      await db.execute(
        'ALTER TABLE auth_user ADD COLUMN flgSuperAdmin INTEGER NOT NULL DEFAULT 0',
      );
    }

    final hasSubscriptionStatus = columns.any(
      (column) => column['name'] == 'codEstadoUsuarioxSuscripcion',
    );
    if (!hasSubscriptionStatus) {
      await db.execute(
        'ALTER TABLE auth_user ADD COLUMN codEstadoUsuarioxSuscripcion INTEGER',
      );
    }
  }

  Future<void> _ensureSubscriptionStructures(Database db) async {
    await db.execute('''
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
      )
    ''');

    await db.execute('''
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
      )
    ''');

    await db.execute('''
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
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_user_profile (
        codProyecto INTEGER PRIMARY KEY,
        codPerfilEmpresa INTEGER,
        desPerfilEmpresa TEXT,
        desDescripcionPerfilEmpresa TEXT,
        updated_at TEXT,
        FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
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
      )
    ''');
  }

  Future<void> _ensureSubscriptionCustomizationStructures(Database db) async {
    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
      )
    ''');

    final restrictionColumns = await db.rawQuery(
      'PRAGMA table_info(anares_restriction)',
    );
    if (!restrictionColumns.any(
      (column) => column['name'] == 'codEstadoxSuscripcion',
    )) {
      await db.execute(
        'ALTER TABLE anares_restriction ADD COLUMN codEstadoxSuscripcion INTEGER',
      );
    }

    final agreementColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_acuerdos)',
    );
    if (!agreementColumns.any(
      (column) => column['name'] == 'codEstadoxSuscripcion',
    )) {
      await db.execute(
        'ALTER TABLE actreu_acuerdos ADD COLUMN codEstadoxSuscripcion INTEGER',
      );
    }

    final agreementPhotoColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_acuerdosfoto)',
    );
    if (!agreementPhotoColumns.any(
      (column) => column['name'] == 'codEstadoxSuscripcion',
    )) {
      await db.execute(
        'ALTER TABLE actreu_acuerdosfoto ADD COLUMN codEstadoxSuscripcion INTEGER',
      );
    }
  }

  Future<void> _ensureRestrictionAreaStructures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS anares_analysis (
        codAnaRes INTEGER PRIMARY KEY,
        codProyecto INTEGER NOT NULL,
        codEstado INTEGER,
        dayFechaCreacion TEXT,
        desUsuarioCreacion TEXT,
        updated_at TEXT,
        FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects_area_member (
        codArea INTEGER PRIMARY KEY,
        desArea TEXT
      )
    ''');

    final areaColumns = await db.rawQuery(
      'PRAGMA table_info(projects_area_member)',
    );
    if (!areaColumns.any((column) => column['name'] == 'desArea')) {
      await db.execute(
        'ALTER TABLE projects_area_member ADD COLUMN desArea TEXT',
      );
    }

    await db.execute('''
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
      )
    ''');

    final analysisAreaColumns = await db.rawQuery(
      'PRAGMA table_info(anares_area)',
    );
    if (!analysisAreaColumns.any((column) => column['name'] == 'cod_Empresa')) {
      await db.execute(
        'ALTER TABLE anares_area ADD COLUMN cod_Empresa INTEGER',
      );
    }
    if (!analysisAreaColumns.any(
      (column) => column['name'] == 'is_codAnaresAreaLocal',
    )) {
      await db.execute(
        'ALTER TABLE anares_area ADD COLUMN is_codAnaresAreaLocal INTEGER NOT NULL DEFAULT 0',
      );
    }

    final restrictionColumns = await db.rawQuery(
      'PRAGMA table_info(anares_restriction)',
    );
    final hasAnalysisArea = restrictionColumns.any(
      (column) => column['name'] == 'codAnaresArea',
    );
    if (!hasAnalysisArea) {
      await db.execute(
        'ALTER TABLE anares_restriction ADD COLUMN codAnaresArea TEXT',
      );
    }

    final frontColumns = await db.rawQuery('PRAGMA table_info(anares_front)');
    if (!frontColumns.any((column) => column['name'] == 'codEstado')) {
      await db.execute(
        'ALTER TABLE anares_front ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!frontColumns.any(
      (column) => column['name'] == 'codAnaResFrenteRemoto',
    )) {
      await db.execute(
        'ALTER TABLE anares_front ADD COLUMN codAnaResFrenteRemoto INTEGER',
      );
    }
    if (!frontColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    )) {
      await db.execute(
        'ALTER TABLE anares_front ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    if (!frontColumns.any(
      (column) => column['name'] == 'desUsuarioModificacion',
    )) {
      await db.execute(
        'ALTER TABLE anares_front ADD COLUMN desUsuarioModificacion TEXT',
      );
    }

    final phaseColumns = await db.rawQuery('PRAGMA table_info(anares_phase)');
    if (!phaseColumns.any((column) => column['name'] == 'codEstado')) {
      await db.execute(
        'ALTER TABLE anares_phase ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!phaseColumns.any(
      (column) => column['name'] == 'codAnaResFaseRemoto',
    )) {
      await db.execute(
        'ALTER TABLE anares_phase ADD COLUMN codAnaResFaseRemoto INTEGER',
      );
    }
    if (!phaseColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    )) {
      await db.execute(
        'ALTER TABLE anares_phase ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    if (!phaseColumns.any(
      (column) => column['name'] == 'desUsuarioModificacion',
    )) {
      await db.execute(
        'ALTER TABLE anares_phase ADD COLUMN desUsuarioModificacion TEXT',
      );
    }
  }

  Future<void> _ensureRestrictionTypeStructures(Database db) async {
    await db.execute('''
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
      )
    ''');

    final typeColumns = await db.rawQuery('PRAGMA table_info(anares_type)');
    final hasNewPrimaryKey = typeColumns.any(
      (column) => column['name'] == 'codTipoRestriccionxEmpresa',
    );
    if (!hasNewPrimaryKey) {
      await _rebuildRestrictionTypeStructures(db, typeColumns);
      return;
    }

    if (!typeColumns.any((column) => column['name'] == 'cod_Empresa')) {
      await db.execute('ALTER TABLE anares_type ADD COLUMN cod_Empresa INTEGER');
    }
    if (!typeColumns.any((column) => column['name'] == 'codTipoRestricciones')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN codTipoRestricciones INTEGER',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'flgIsDefault')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN flgIsDefault INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'codEstado')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'dayFechaCreacion')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN dayFechaCreacion TEXT',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'dayFechaModificacion')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'codUsuarioCreacion')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN codUsuarioCreacion INTEGER',
      );
    }
    if (!typeColumns.any((column) => column['name'] == 'codUsuarioModificacion')) {
      await db.execute(
        'ALTER TABLE anares_type ADD COLUMN codUsuarioModificacion INTEGER',
      );
    }
  }

  Future<void> _rebuildRestrictionTypeStructures(
    Database db,
    List<Map<String, Object?>> typeColumns,
  ) async {
    final legacyNames = typeColumns
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();
    final legacyIdColumn = legacyNames.contains('codTipoRestriccionxEmpresa')
        ? 'codTipoRestriccionxEmpresa'
        : 'codTipoRestriccion';
    final legacyMasterColumn = legacyNames.contains('codTipoRestricciones')
        ? 'codTipoRestricciones'
        : (legacyNames.contains('codTipoRestriccion')
              ? 'codTipoRestriccion'
              : 'NULL');
    final legacyLabelColumn = legacyNames.contains('desTipoRestriccion')
        ? 'desTipoRestriccion'
        : 'NULL';
    final legacyDefaultColumn = legacyNames.contains('flgIsDefault')
        ? 'IFNULL(flgIsDefault, 0)'
        : '0';
    final legacyStatusColumn = legacyNames.contains('codEstado')
        ? 'IFNULL(codEstado, 1)'
        : '1';
    final legacyCompanyColumn = legacyNames.contains('cod_Empresa')
        ? 'cod_Empresa'
        : 'NULL';
    final legacyCreatedAtColumn = legacyNames.contains('dayFechaCreacion')
        ? 'dayFechaCreacion'
        : 'NULL';
    final legacyUpdatedAtDateColumn = legacyNames.contains('dayFechaModificacion')
        ? 'dayFechaModificacion'
        : 'NULL';
    final legacyCreatedByColumn = legacyNames.contains('codUsuarioCreacion')
        ? 'codUsuarioCreacion'
        : 'NULL';
    final legacyUpdatedByColumn = legacyNames.contains('codUsuarioModificacion')
        ? 'codUsuarioModificacion'
        : 'NULL';
    final legacySyncUpdatedAtColumn = legacyNames.contains('updated_at')
        ? 'updated_at'
        : 'NULL';

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE anares_type RENAME TO anares_type_legacy');
        await txn.execute('''
          CREATE TABLE anares_type (
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
          )
        ''');
        await txn.execute('''
          INSERT INTO anares_type (
            codTipoRestriccionxEmpresa,
            cod_Empresa,
            codTipoRestricciones,
            desTipoRestriccion,
            flgIsDefault,
            codEstado,
            dayFechaCreacion,
            dayFechaModificacion,
            codUsuarioCreacion,
            codUsuarioModificacion,
            updated_at
          )
          SELECT
            $legacyIdColumn,
            $legacyCompanyColumn,
            $legacyMasterColumn,
            $legacyLabelColumn,
            $legacyDefaultColumn,
            $legacyStatusColumn,
            $legacyCreatedAtColumn,
            $legacyUpdatedAtDateColumn,
            $legacyCreatedByColumn,
            $legacyUpdatedByColumn,
            $legacySyncUpdatedAtColumn
          FROM anares_type_legacy
          WHERE $legacyIdColumn IS NOT NULL
        ''');

        await txn.execute(
          'ALTER TABLE anares_restriction RENAME TO anares_restriction_legacy',
        );
        await txn.execute('''
          CREATE TABLE anares_restriction (
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
          )
        ''');
        await txn.execute('''
          INSERT INTO anares_restriction (
            codAnaResActividad,
            codProyecto,
            codAnaRes,
            codAnaResFrente,
            codAnaResFase,
            desFrente,
            desFase,
            desActividad,
            desRestriccion,
            codTipoRestriccion,
            desTipoRestriccion,
            dayFechaRequerida,
            dayFechaConciliada,
            dayFechaLevantamiento,
            idUsuarioResponsable,
            desResponsable,
            codEstadoActividad,
            codEstadoxSuscripcion,
            desEstadoActividad,
            colorEstado,
            codAnaresArea,
            codUsuarioSolicitante,
            desSolicitante,
            is_completed,
            is_overdue,
            is_due_today,
            is_pending,
            is_in_progress,
            priority_order,
            dayFechaCreacion,
            dayFechaModificacion,
            sync_status,
            updated_at
          )
          SELECT
            codAnaResActividad,
            codProyecto,
            codAnaRes,
            codAnaResFrente,
            codAnaResFase,
            desFrente,
            desFase,
            desActividad,
            desRestriccion,
            codTipoRestriccion,
            desTipoRestriccion,
            dayFechaRequerida,
            dayFechaConciliada,
            dayFechaLevantamiento,
            idUsuarioResponsable,
            desResponsable,
            codEstadoActividad,
            codEstadoxSuscripcion,
            desEstadoActividad,
            colorEstado,
            codAnaresArea,
            codUsuarioSolicitante,
            desSolicitante,
            is_completed,
            is_overdue,
            is_due_today,
            is_pending,
            is_in_progress,
            priority_order,
            dayFechaCreacion,
            dayFechaModificacion,
            sync_status,
            updated_at
          FROM anares_restriction_legacy
        ''');
        await txn.execute('DROP TABLE anares_restriction_legacy');
        await txn.execute('DROP TABLE anares_type_legacy');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _ensureControlHitosStructures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conhit_tipohito (
        codTipoHito INTEGER PRIMARY KEY,
        desTipoHito TEXT NOT NULL,
        orden INTEGER,
        codEstado INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conhit_tipoclasificacion (
        codTipoClasificacion INTEGER PRIMARY KEY,
        desTipoClasificacion TEXT NOT NULL,
        orden INTEGER,
        codEstado INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conhit_statusinterno (
        codEstado TEXT PRIMARY KEY,
        desEstado TEXT NOT NULL,
        desColor TEXT,
        desIcono TEXT,
        orden INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conhit_statuscontractual (
        codEstado TEXT PRIMARY KEY,
        desEstado TEXT NOT NULL,
        desColor TEXT,
        desIcono TEXT,
        orden INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at TEXT,
        FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE,
        FOREIGN KEY (codConHit) REFERENCES conhit_controlhitos(codConHit) ON DELETE CASCADE
      )
    ''');

    // Ensure flgAplicaHitoGeneral column exists
    final generalColumns = await db.rawQuery(
      'PRAGMA table_info(conhit_general)',
    );
    final hasFlgAplica = generalColumns.any(
      (column) => column['name'] == 'flgAplicaHitoGeneral',
    );
    if (!hasFlgAplica) {
      await db.execute(
        'ALTER TABLE conhit_general ADD COLUMN flgAplicaHitoGeneral INTEGER NOT NULL DEFAULT 0',
      );
    }

    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
      )
    ''');
    await db.execute('''
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
        PRIMARY KEY (codConHit, codProyecto, codProyIntegrante)
      )
    ''');
    await db.execute('''
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
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at TEXT,
        FOREIGN KEY (codConHitDetalleHitos) REFERENCES conhit_detallehitos(codConHitDetalleHitos) ON DELETE CASCADE
      )
    ''');

    final milestoneColumns = await db.rawQuery(
      'PRAGMA table_info(conhit_detallehitos)',
    );
    final hasCodEstado = milestoneColumns.any(
      (column) => column['name'] == 'codEstado',
    );
    if (!hasCodEstado) {
      await db.execute(
        'ALTER TABLE conhit_detallehitos ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }
    final hasMilestoneRemoteId = milestoneColumns.any(
      (column) => column['name'] == 'codConHitDetalleHitosRemoto',
    );
    if (!hasMilestoneRemoteId) {
      await db.execute(
        'ALTER TABLE conhit_detallehitos ADD COLUMN codConHitDetalleHitosRemoto INTEGER',
      );
    }

    final milestoneGeneralColumns = await db.rawQuery(
      'PRAGMA table_info(conhit_general)',
    );
    final hasGeneralRemoteId = milestoneGeneralColumns.any(
      (column) => column['name'] == 'codConHitGeneralRemoto',
    );
    if (!hasGeneralRemoteId) {
      await db.execute(
        'ALTER TABLE conhit_general ADD COLUMN codConHitGeneralRemoto INTEGER',
      );
    }

    final milestoneExtensionColumns = await db.rawQuery(
      'PRAGMA table_info(conthit_detallehitosamp)',
    );
    final hasExtensionRemoteId = milestoneExtensionColumns.any(
      (column) => column['name'] == 'codConHitDetalleHitosAmpRemoto',
    );
    if (!hasExtensionRemoteId) {
      await db.execute(
        'ALTER TABLE conthit_detallehitosamp ADD COLUMN codConHitDetalleHitosAmpRemoto INTEGER',
      );
    }
    final hasExtensionStatus = milestoneExtensionColumns.any(
      (column) => column['name'] == 'codEstado',
    );
    if (!hasExtensionStatus) {
      await db.execute(
        'ALTER TABLE conthit_detallehitosamp ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }

    final milestoneDocumentColumns = await db.rawQuery(
      'PRAGMA table_info(conhit_archivosfechareal)',
    );
    final hasDocumentRemoteId = milestoneDocumentColumns.any(
      (column) => column['name'] == 'codConhitArchivosFechaRealRemoto',
    );
    if (!hasDocumentRemoteId) {
      await db.execute(
        'ALTER TABLE conhit_archivosfechareal ADD COLUMN codConhitArchivosFechaRealRemoto INTEGER',
      );
    }
  }

  Future<void> _ensureActreuStructures(Database db) async {
    final categoryColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_categoria)',
    );
    if (!categoryColumns.any(
      (column) => column['name'] == 'codActReuCategoriaRemoto',
    )) {
      await db.execute(
        'ALTER TABLE actreu_categoria ADD COLUMN codActReuCategoriaRemoto INTEGER',
      );
    }

    final subcategoryColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_subcategoria)',
    );
    if (!subcategoryColumns.any(
      (column) => column['name'] == 'codActReuSubCategoriaRemoto',
    )) {
      await db.execute(
        'ALTER TABLE actreu_subcategoria ADD COLUMN codActReuSubCategoriaRemoto INTEGER',
      );
    }

    final sessionColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_reuniones)',
    );
    if (!sessionColumns.any(
      (column) => column['name'] == 'codActReuReunionesRemoto',
    )) {
      await db.execute(
        'ALTER TABLE actreu_reuniones ADD COLUMN codActReuReunionesRemoto INTEGER',
      );
    }

    final agreementColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_acuerdos)',
    );
    if (!agreementColumns.any(
      (column) => column['name'] == 'codActReuAcuerdosRemoto',
    )) {
      await db.execute(
        'ALTER TABLE actreu_acuerdos ADD COLUMN codActReuAcuerdosRemoto INTEGER',
      );
    }

    final participantColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_participantes)',
    );
    final hasParticipantModifiedAt = participantColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    );
    if (!hasParticipantModifiedAt) {
      await db.execute(
        'ALTER TABLE actreu_participantes ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    final hasParticipantModifiedBy = participantColumns.any(
      (column) => column['name'] == 'desUsuarioModificacion',
    );
    if (!hasParticipantModifiedBy) {
      await db.execute(
        'ALTER TABLE actreu_participantes ADD COLUMN desUsuarioModificacion TEXT',
      );
    }

    final groupColumns = await db.rawQuery(
      'PRAGMA table_info(actreu_grupoacuerdo)',
    );
    if (!groupColumns.any(
      (column) => column['name'] == 'codActReuGrupoAcuerdoRemoto',
    )) {
      await db.execute(
        'ALTER TABLE actreu_grupoacuerdo ADD COLUMN codActReuGrupoAcuerdoRemoto INTEGER',
      );
    }
    if (!groupColumns.any((column) => column['name'] == 'dayFechaCreacion')) {
      await db.execute(
        'ALTER TABLE actreu_grupoacuerdo ADD COLUMN dayFechaCreacion TEXT',
      );
    }
    if (!groupColumns.any((column) => column['name'] == 'desUsuarioCreacion')) {
      await db.execute(
        'ALTER TABLE actreu_grupoacuerdo ADD COLUMN desUsuarioCreacion TEXT',
      );
    }
    if (!groupColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    )) {
      await db.execute(
        'ALTER TABLE actreu_grupoacuerdo ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    if (!groupColumns.any(
      (column) => column['name'] == 'desUsuarioModificacion',
    )) {
      await db.execute(
        'ALTER TABLE actreu_grupoacuerdo ADD COLUMN desUsuarioModificacion TEXT',
      );
    }
  }

  Future<void> _ensureAvanceGraficoStructures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_avancegrafico (
        codAvaGrafico INTEGER PRIMARY KEY,
        codAvaGraficoRemoto INTEGER,
        codProyecto INTEGER NOT NULL,
        codEstado INTEGER DEFAULT 1,
        dayFechaCreacion TEXT,
        desUsuarioCreacion TEXT,
        vistaSeleccionada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_integrantes (
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        codProyIntegrante INTEGER NOT NULL,
        codEstado INTEGER DEFAULT 1,
        dayFechaCreacion TEXT,
        desUsuarioCreacion TEXT,
        dayFechaModificacion TEXT,
        desUsuarioModificacion TEXT,
        PRIMARY KEY (codProyecto, codAvaGrafico, codProyIntegrante)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_estados (
        codEstado INTEGER PRIMARY KEY,
        desEstado TEXT,
        desFase TEXT,
        codColor TEXT,
        desColor TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_forma (
        CodForma INTEGER PRIMARY KEY,
        DesForma TEXT,
        DesAbrev TEXT,
        DesIcon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_sentidohorario (
        CodSentido INTEGER PRIMARY KEY,
        DesSentido TEXT,
        DesAbrev TEXT,
        DesIcon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_tipolado (
        CodTipoLado INTEGER PRIMARY KEY,
        DesLado TEXT,
        DesAbrev TEXT,
        DesIcon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_faseuno (
        codFaseUno INTEGER PRIMARY KEY,
        codFaseUnoRemoto INTEGER,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        DesFaseUno TEXT,
        Comentarios TEXT,
        desResOrdenTipoLados TEXT,
        CodForma INTEGER,
        CodSentido INTEGER,
        flgNivelesGlobales INTEGER NOT NULL DEFAULT 0,
        numNivelesGlobales INTEGER NOT NULL DEFAULT 0,
        dayFechaCreacion TEXT,
        codUsuarioCreacion TEXT,
        dayFechaModificacion TEXT,
        desUsuarioModificacion TEXT,
        auto_generate_pdf_enabled INTEGER NOT NULL DEFAULT 0,
        auto_generate_pdf_iso_day INTEGER,
        auto_generate_pdf_hours TEXT
      )
    ''');
    final faseUnoColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_faseuno)',
    );
    final hasFlgNivelesGlobales = faseUnoColumns.any(
      (column) => column['name'] == 'flgNivelesGlobales',
    );
    if (!hasFlgNivelesGlobales) {
      await db.execute(
        'ALTER TABLE avagra_faseuno ADD COLUMN flgNivelesGlobales INTEGER NOT NULL DEFAULT 0',
      );
    }
    final hasNumNivelesGlobales = faseUnoColumns.any(
      (column) => column['name'] == 'numNivelesGlobales',
    );
    if (!hasNumNivelesGlobales) {
      await db.execute(
        'ALTER TABLE avagra_faseuno ADD COLUMN numNivelesGlobales INTEGER NOT NULL DEFAULT 0',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_secciones (
        codSecciones INTEGER PRIMARY KEY,
        codSeccionesRemoto INTEGER,
        desSecciones TEXT,
        desAbrev TEXT,
        numNiveles INTEGER,
        numPanios INTEGER,
        numOrdenTipoLado INTEGER,
        CodTipoLado INTEGER,
        codFaseUno INTEGER NOT NULL,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        codEstado INTEGER NOT NULL DEFAULT 1,
        codUsuarioCreacion TEXT,
        dayFechaCreacion TEXT,
        codUsuarioModificacion TEXT,
        dayFechaModificacion TEXT
      )
    ''');
    final seccionColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_secciones)',
    );
    final hasCodEstadoSeccion = seccionColumns.any(
      (column) => column['name'] == 'codEstado',
    );
    if (!hasCodEstadoSeccion) {
      await db.execute(
        'ALTER TABLE avagra_secciones ADD COLUMN codEstado INTEGER NOT NULL DEFAULT 1',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_posiciones (
        codPosition INTEGER PRIMARY KEY,
        codPositionRemoto INTEGER,
        codSecciones INTEGER NOT NULL,
        desNumeracion TEXT,
        numNivel INTEGER,
        numPanio INTEGER,
        desPosicion TEXT,
        desAbrev TEXT,
        codEstado INTEGER,
        codUsuarioCreacion TEXT,
        dayFechaCreacion TEXT,
        codUsuarioModificacion TEXT,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_faseunodocumentos (
        codFaseUnoDocumentos INTEGER PRIMARY KEY,
        desNombre TEXT,
        desLink TEXT,
        codFaseUno INTEGER NOT NULL,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        dayFechaCreacion TEXT,
        codUsuarioCreacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_fasedos (
        codFaseDos INTEGER PRIMARY KEY,
        codFaseDosRemoto INTEGER,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        desFaseDos TEXT,
        desComentarios TEXT,
        flgPisosUniformes INTEGER DEFAULT 0,
        numPisosUniformes INTEGER,
        dayFechaCreacion TEXT,
        dayFechaModificacion TEXT,
        auto_generate_pdf_enabled INTEGER NOT NULL DEFAULT 0,
        auto_generate_pdf_iso_day INTEGER,
        auto_generate_pdf_hours TEXT
      )
    ''');
    final faseDosColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_fasedos)',
    );
    final hasFaseDosFechaCreacion = faseDosColumns.any(
      (column) => column['name'] == 'dayFechaCreacion',
    );
    if (!hasFaseDosFechaCreacion) {
      await db.execute(
        'ALTER TABLE avagra_fasedos ADD COLUMN dayFechaCreacion TEXT',
      );
    }
    final hasFaseDosFechaModificacion = faseDosColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    );
    if (!hasFaseDosFechaModificacion) {
      await db.execute(
        'ALTER TABLE avagra_fasedos ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_actividades (
        codActividades INTEGER PRIMARY KEY,
        codActividadesRemoto INTEGER,
        desActividades TEXT,
        numPisos INTEGER,
        sotanos INTEGER DEFAULT 0,
        numSectores INTEGER,
        codFaseDos INTEGER,
        codProyecto INTEGER,
        codAvaGrafico INTEGER,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT,
        codEstado INTEGER,
        desAbrev TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_cuadros (
        codCuadros INTEGER PRIMARY KEY,
        codCuadrosRemoto INTEGER,
        codActividades INTEGER,
        numOrden INTEGER,
        numPiso INTEGER,
        numSector INTEGER,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT,
        codEstado INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_fotos (
        codFoto INTEGER PRIMARY KEY,
        codFaseDos INTEGER,
        codProyecto INTEGER,
        codAvaGrafico INTEGER,
        desFoto TEXT,
        desUrl TEXT,
        dayFechaCreacion TEXT,
        codUsuarioCreacion INTEGER,
        dayFechaModificacion TEXT,
        codUsuarioModificacion INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_fasetres (
        codFaseTres INTEGER PRIMARY KEY,
        codFaseTresRemoto INTEGER,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        desFaseTres TEXT,
        desComentarios TEXT,
        numPisos INTEGER,
        numSectores INTEGER,
        numActividades INTEGER,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    final faseTresColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_fasetres)',
    );
    final hasFaseTresUsuarioCreacion = faseTresColumns.any(
      (column) => column['name'] == 'codUsuarioCreacion',
    );
    if (!hasFaseTresUsuarioCreacion) {
      await db.execute(
        'ALTER TABLE avagra_fasetres ADD COLUMN codUsuarioCreacion INTEGER',
      );
    }
    final hasFaseTresFechaCreacion = faseTresColumns.any(
      (column) => column['name'] == 'dayFechaCreacion',
    );
    if (!hasFaseTresFechaCreacion) {
      await db.execute(
        'ALTER TABLE avagra_fasetres ADD COLUMN dayFechaCreacion TEXT',
      );
    }
    final hasFaseTresUsuarioModificacion = faseTresColumns.any(
      (column) => column['name'] == 'codUsuarioModificacion',
    );
    if (!hasFaseTresUsuarioModificacion) {
      await db.execute(
        'ALTER TABLE avagra_fasetres ADD COLUMN codUsuarioModificacion INTEGER',
      );
    }
    final hasFaseTresFechaModificacion = faseTresColumns.any(
      (column) => column['name'] == 'dayFechaModificacion',
    );
    if (!hasFaseTresFechaModificacion) {
      await db.execute(
        'ALTER TABLE avagra_fasetres ADD COLUMN dayFechaModificacion TEXT',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_pisos (
        codPiso INTEGER PRIMARY KEY,
        codPisoRemoto INTEGER,
        codFaseTres INTEGER NOT NULL,
        codProyecto INTEGER NOT NULL,
        codAvaGrafico INTEGER NOT NULL,
        desAbrev TEXT,
        desNombre TEXT,
        numOrden INTEGER,
        desLinkPlano TEXT,
        desNombrePlano TEXT,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_sectores (
        codSector INTEGER PRIMARY KEY,
        codSectorRemoto INTEGER,
        codFaseTres INTEGER,
        codProyecto INTEGER,
        codAvaGrafico INTEGER,
        desNombre TEXT,
        desAbrev TEXT,
        desDescripcion TEXT,
        jsonPosicionamientoPlano TEXT,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_sectoresxpisos (
        codSectorxPiso INTEGER PRIMARY KEY,
        codSectorxPisoRemoto INTEGER,
        codPiso INTEGER NOT NULL,
        codSector INTEGER NOT NULL,
        desNombre TEXT,
        desAbrev TEXT,
        desDescripcion TEXT,
        codEstado INTEGER,
        numPorcentajeCompletados REAL,
        numPorcentajeAprobadosCalidad REAL,
        jsonPosicionamientoPlano TEXT,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_actividad (
        codActividad INTEGER PRIMARY KEY,
        codActividadRemoto INTEGER,
        codFaseTres INTEGER,
        codProyecto INTEGER,
        codAvaGrafico INTEGER,
        desNombre TEXT,
        desDescripcion TEXT,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_actividadxpisos (
        codActividadxPiso INTEGER PRIMARY KEY,
        codActividadxPisoRemoto INTEGER,
        codActividad INTEGER NOT NULL,
        codPiso INTEGER NOT NULL,
        desAbrev TEXT,
        desDescripcion TEXT,
        codEstado INTEGER,
        numOrden INTEGER,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avagra_actividadxsectorxpisos (
        codActividadxSectorxPiso INTEGER PRIMARY KEY,
        codActividadxSectorxPisoRemoto INTEGER,
        codActividadxPiso INTEGER NOT NULL,
        codSectorxPiso INTEGER NOT NULL,
        codEstado INTEGER,
        codUsuarioCreacion INTEGER,
        dayFechaCreacion TEXT,
        codUsuarioModificacion INTEGER,
        dayFechaModificacion TEXT
      )
    ''');
    final sectorColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_sectores)',
    );
    final hasSectorAbbr = sectorColumns.any(
      (column) => column['name'] == 'desAbrev',
    );
    if (!hasSectorAbbr) {
      await db.execute('ALTER TABLE avagra_sectores ADD COLUMN desAbrev TEXT');
    }
    final sectorFloorColumns = await db.rawQuery(
      'PRAGMA table_info(avagra_sectoresxpisos)',
    );
    final hasSectorFloorAbbr = sectorFloorColumns.any(
      (column) => column['name'] == 'desAbrev',
    );
    if (!hasSectorFloorAbbr) {
      await db.execute(
        'ALTER TABLE avagra_sectoresxpisos ADD COLUMN desAbrev TEXT',
      );
    }

    Future<void> ensureRemoteColumn(String table, String column) async {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final hasColumn = columns.any((info) => info['name'] == column);
      if (!hasColumn) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column INTEGER');
      }
    }

    await ensureRemoteColumn('avagra_avancegrafico', 'codAvaGraficoRemoto');
    await ensureRemoteColumn('avagra_faseuno', 'codFaseUnoRemoto');
    await ensureRemoteColumn('avagra_secciones', 'codSeccionesRemoto');
    await ensureRemoteColumn('avagra_posiciones', 'codPositionRemoto');
    await ensureRemoteColumn('avagra_fasedos', 'codFaseDosRemoto');
    await ensureRemoteColumn('avagra_actividades', 'codActividadesRemoto');
    await ensureRemoteColumn('avagra_cuadros', 'codCuadrosRemoto');
    await ensureRemoteColumn('avagra_fasetres', 'codFaseTresRemoto');
    await ensureRemoteColumn('avagra_pisos', 'codPisoRemoto');
    await ensureRemoteColumn('avagra_sectores', 'codSectorRemoto');
    await ensureRemoteColumn('avagra_actividad', 'codActividadRemoto');
    await ensureRemoteColumn('avagra_sectoresxpisos', 'codSectorxPisoRemoto');
    await ensureRemoteColumn(
      'avagra_actividadxpisos',
      'codActividadxPisoRemoto',
    );
    await ensureRemoteColumn(
      'avagra_actividadxsectorxpisos',
      'codActividadxSectorxPisoRemoto',
    );
  }

  Future<void> _ensureHubIndicatorPrefs(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hub_indicator_prefs (
        indicator_key TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        display_type TEXT NOT NULL DEFAULT 'card',
        custom_param TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT,
        PRIMARY KEY (indicator_key, user_id)
      )
    ''');
  }

  Future<void> _ensureModuleInsightsStructures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS module_insights (
        codProyecto INTEGER NOT NULL,
        desModulo TEXT NOT NULL,
        desInsightKey TEXT NOT NULL,
        desSeverity TEXT NOT NULL,
        desTitle TEXT NOT NULL,
        desMessage TEXT NOT NULL,
        desIconName TEXT NOT NULL,
        is_resolved INTEGER NOT NULL DEFAULT 0,
        dayResolvedAt TEXT,
        updated_at TEXT,
        PRIMARY KEY (codProyecto, desModulo, desInsightKey),
        FOREIGN KEY (codProyecto) REFERENCES projects_project(codProyecto) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_module_insights_project_module
      ON module_insights(codProyecto, desModulo, desSeverity, is_resolved)
    ''');
  }

  Future<void> _ensureInsightRuleConfigStructures(Database db) async {
    // Migrate: if the old per-project table exists (has codProyecto column),
    // drop it and recreate as per-user table (codUsuario).
    final cols = await db.rawQuery("PRAGMA table_info('insight_rule_config')");
    final hasOldSchema = cols.any((c) => c['name'] == 'codProyecto');
    if (hasOldSchema) {
      await db.execute('DROP TABLE IF EXISTS insight_rule_config');
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS insight_rule_config (
        codUsuario INTEGER NOT NULL,
        desModulo TEXT NOT NULL,
        desRuleKey TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        thresholdsJson TEXT NOT NULL DEFAULT '{}',
        updated_at TEXT,
        PRIMARY KEY (codUsuario, desModulo, desRuleKey)
      )
    ''');
  }

  Future<void> _seed(Database db) async {
    final projectCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM projects_project'),
    );
    final now = _limaNowIso8601();

    if ((projectCount ?? 0) > 0) {
      await db.update(
        'auth_user',
        {'password': '123456', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [7],
      );
      await _seedAreaCatalog(db);
      await _seedControlHitosCatalogs(db, now);
      await _seedControlHitos(db, now);
      await _ensureDefaultSettings(db, now);
      return;
    }

    final batch = db.batch();

    batch.insert('auth_user', {
      'id': 7,
      'name': 'Diego',
      'lastname': 'Warthon',
      'email': 'diego@direktor.pe',
      'password': '123456',
      'celular': '999999999',
      'nombreempresa': 'Direktor',
      'codCargo': 1,
      'updated_at': now,
    });

    batch.insert('projects_project', {
      'codProyecto': 101,
      'desNombreProyecto': 'Proyecto A',
      'codEstado': 1,
      'codEmpresa': 1,
      'desEmpresa': 'Direktor',
      'codTipoProyecto': 1,
      'desTipoProyecto': 'Edificacion',
      'codMoneda': 1,
      'desMoneda': 'Soles',
      'desSimboloMoneda': 'S/',
      'codUbigeo': 150101,
      'desUbigeo': 'Lima',
      'desDireccion': 'Av. Primavera 123',
      'dayFechaInicio': '2026-01-10',
      'is_last_selected': 1,
      'updated_at': now,
    });
    batch.insert('projects_project', {
      'codProyecto': 102,
      'desNombreProyecto': 'Proyecto B',
      'codEstado': 1,
      'codEmpresa': 1,
      'desEmpresa': 'Direktor',
      'codTipoProyecto': 1,
      'desTipoProyecto': 'Infraestructura',
      'codMoneda': 1,
      'desMoneda': 'Soles',
      'desSimboloMoneda': 'S/',
      'codUbigeo': 150122,
      'desUbigeo': 'Lima',
      'desDireccion': 'Jr. Los Olivos 450',
      'dayFechaInicio': '2026-02-01',
      'is_last_selected': 0,
      'updated_at': now,
    });
    batch.insert('projects_project', {
      'codProyecto': 103,
      'desNombreProyecto': 'Proyecto C',
      'codEstado': 1,
      'codEmpresa': 1,
      'desEmpresa': 'Direktor',
      'codTipoProyecto': 1,
      'desTipoProyecto': 'Industrial',
      'codMoneda': 1,
      'desMoneda': 'Soles',
      'desSimboloMoneda': 'S/',
      'codUbigeo': 150131,
      'desUbigeo': 'Lima',
      'desDireccion': 'Parque Industrial 50',
      'dayFechaInicio': '2026-02-15',
      'is_last_selected': 0,
      'updated_at': now,
    });

    final members = [
      {
        'codProyIntegrante': 1001,
        'codProyecto': 101,
        'user_id': 7,
        'codArea': 1,
        'desArea': 'Supervision',
        'codRolIntegrante': 1,
        'desRolIntegrante': 'Supervisor de obra',
        'codEstadoInvitacion': 'OK',
        'desCorreo': 'diego@direktor.pe',
        'numCelular': '999999999',
        'updated_at': now,
      },
      {
        'codProyIntegrante': 1002,
        'codProyecto': 101,
        'user_id': 8,
        'codArea': 2,
        'desArea': 'Planeamiento',
        'codRolIntegrante': 2,
        'desRolIntegrante': 'Planner',
        'codEstadoInvitacion': 'OK',
        'desCorreo': 'juan@direktor.pe',
        'numCelular': '988111111',
        'updated_at': now,
      },
      {
        'codProyIntegrante': 1003,
        'codProyecto': 101,
        'user_id': 9,
        'codArea': 3,
        'desArea': 'Produccion',
        'codRolIntegrante': 3,
        'desRolIntegrante': 'Jefe de frente',
        'codEstadoInvitacion': 'OK',
        'desCorreo': 'maria@direktor.pe',
        'numCelular': '977222222',
        'updated_at': now,
      },
      {
        'codProyIntegrante': 1004,
        'codProyecto': 101,
        'user_id': 10,
        'codArea': 4,
        'desArea': 'Logistica',
        'codRolIntegrante': 4,
        'desRolIntegrante': 'Coordinador',
        'codEstadoInvitacion': 'OK',
        'desCorreo': 'carlos@direktor.pe',
        'numCelular': '966333333',
        'updated_at': now,
      },
    ];
    for (final row in members) {
      batch.insert('projects_member', row);
    }

    for (final row in _areaSeedRows()) {
      batch.insert('projects_area_member', row);
    }

    for (final row in [
      {
        'codAnaRes': 1,
        'codProyecto': 101,
        'codEstado': 0,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'Sistema',
        'updated_at': now,
      },
    ]) {
      batch.insert('anares_analysis', row);
    }

    for (final row in [
      {
        'codAnaresArea': 1,
        'codProyecto': 101,
        'codArea': 2,
        'desArea': 'Planeamiento',
        'cod_Empresa': 1,
        'bgColor': '#FFFFFF',
        'updated_at': now,
        'is_codAnaresAreaLocal': 0,
      },
      {
        'codAnaresArea': 2,
        'codProyecto': 101,
        'codArea': 4,
        'desArea': 'Logistica',
        'cod_Empresa': 1,
        'bgColor': '#FFFFFF',
        'updated_at': now,
        'is_codAnaresAreaLocal': 0,
      },
      {
        'codAnaresArea': 3,
        'codProyecto': 101,
        'codArea': 1,
        'desArea': 'Supervision',
        'cod_Empresa': 1,
        'bgColor': '#FFFFFF',
        'updated_at': now,
        'is_codAnaresAreaLocal': 0,
      },
    ]) {
      batch.insert('anares_area', row);
    }

    final fronts = [
      {
        'codAnaResFrente': 201,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFrente': 'Torre A - Frente Norte de obra',
        'updated_at': now,
      },
      {
        'codAnaResFrente': 202,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFrente': 'Sotano 1',
        'updated_at': now,
      },
      {
        'codAnaResFrente': 203,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFrente': 'Lobby principal',
        'updated_at': now,
      },
    ];
    for (final row in fronts) {
      batch.insert('anares_front', row);
    }

    final phases = [
      {
        'codAnaResFase': 301,
        'codAnaResFrente': 201,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFase': 'Estructuras y concreto armado',
        'bgColor': '#0A66B7',
        'updated_at': now,
      },
      {
        'codAnaResFase': 302,
        'codAnaResFrente': 202,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFase': 'Instalaciones sanitarias',
        'bgColor': '#F0A11E',
        'updated_at': now,
      },
      {
        'codAnaResFase': 303,
        'codAnaResFrente': 203,
        'codProyecto': 101,
        'codAnaRes': 1,
        'desAnaResFase': 'Acabados interiores y carpinteria',
        'bgColor': '#F26A3D',
        'updated_at': now,
      },
    ];
    for (final row in phases) {
      batch.insert('anares_phase', row);
    }

    for (final row in [
      {
        'codTipoRestriccionxEmpresa': 1,
        'codTipoRestricciones': 1,
        'desTipoRestriccion': 'Permisos',
        'flgIsDefault': 1,
        'codEstado': 1,
        'updated_at': now,
      },
      {
        'codTipoRestriccionxEmpresa': 2,
        'codTipoRestricciones': 2,
        'desTipoRestriccion': 'Materiales',
        'flgIsDefault': 1,
        'codEstado': 1,
        'updated_at': now,
      },
      {
        'codTipoRestriccionxEmpresa': 3,
        'codTipoRestricciones': 3,
        'desTipoRestriccion': 'Planos',
        'flgIsDefault': 1,
        'codEstado': 1,
        'updated_at': now,
      },
    ]) {
      batch.insert('anares_type', row);
    }

    for (final row in [
      {
        'codEstado': 'pending',
        'desEstado': 'Pendiente',
        'iconColor': '#98A3B3',
        'codModulo': 1,
        'codElementoControl': 1,
        'updated_at': now,
      },
      {
        'codEstado': 'in_progress',
        'desEstado': 'En proceso',
        'iconColor': '#F0A11E',
        'codModulo': 1,
        'codElementoControl': 2,
        'updated_at': now,
      },
      {
        'codEstado': 'completed',
        'desEstado': 'Completado',
        'iconColor': '#1B8E5A',
        'codModulo': 1,
        'codElementoControl': 3,
        'updated_at': now,
      },
      {
        'codEstado': 'overdue',
        'desEstado': 'Retrasado',
        'iconColor': '#D64545',
        'codModulo': 1,
        'codElementoControl': 4,
        'updated_at': now,
      },
    ]) {
      batch.insert('anares_status', row);
    }

    final restrictions = [
      {
        'codAnaResActividad': 401,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 201,
        'codAnaResFase': 301,
        'codAnaresArea': '1',
        'desFrente': 'Torre A - Frente Norte de obra',
        'desFase': 'Estructuras y concreto armado',
        'desActividad': 'Tramitar aprobacion municipal',
        'desRestriccion':
            'Falta permiso municipal para liberar el frente y continuar con el avance programado.',
        'codTipoRestriccion': 1,
        'desTipoRestriccion': 'Permisos',
        'dayFechaRequerida': '2026-03-12',
        'idUsuarioResponsable': 8,
        'desResponsable': 'Juan Perez',
        'codEstadoActividad': 'overdue',
        'desEstadoActividad': 'Retrasado',
        'colorEstado': '#D64545',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 0,
        'is_overdue': 1,
        'is_due_today': 0,
        'is_pending': 0,
        'is_in_progress': 0,
        'priority_order': 1,
        'dayFechaCreacion': '2026-03-01T09:00:00',
        'dayFechaModificacion': '2026-03-10T11:40:00',
        'sync_status': 'pending',
        'updated_at': now,
      },
      {
        'codAnaResActividad': 402,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 202,
        'codAnaResFase': 302,
        'codAnaresArea': '2',
        'desFrente': 'Sotano 1',
        'desFase': 'Instalaciones sanitarias',
        'desActividad': 'Gestionar llegada de materiales',
        'desRestriccion':
            'Material no llega segun cronograma de abastecimiento.',
        'codTipoRestriccion': 2,
        'desTipoRestriccion': 'Materiales',
        'dayFechaRequerida': '2026-03-12',
        'idUsuarioResponsable': 10,
        'desResponsable': 'Carlos Ruiz',
        'codEstadoActividad': 'in_progress',
        'desEstadoActividad': 'En proceso',
        'colorEstado': '#F0A11E',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 0,
        'is_overdue': 0,
        'is_due_today': 1,
        'is_pending': 0,
        'is_in_progress': 1,
        'priority_order': 2,
        'dayFechaCreacion': '2026-03-02T09:00:00',
        'dayFechaModificacion': '2026-03-10T10:00:00',
        'sync_status': 'synced',
        'updated_at': now,
      },
      {
        'codAnaResActividad': 403,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 203,
        'codAnaResFase': 303,
        'codAnaresArea': '3',
        'desFrente': 'Lobby principal',
        'desFase': 'Acabados interiores y carpinteria',
        'desActividad': 'Coordinar entrega de planos revisados',
        'desRestriccion':
            'Coordinar entrega de planos revisados con arquitectura.',
        'codTipoRestriccion': 3,
        'desTipoRestriccion': 'Planos',
        'dayFechaRequerida': '2026-03-14',
        'idUsuarioResponsable': 9,
        'desResponsable': 'Maria Torres',
        'codEstadoActividad': 'pending',
        'desEstadoActividad': 'Pendiente',
        'colorEstado': '#98A3B3',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 0,
        'is_overdue': 0,
        'is_due_today': 0,
        'is_pending': 1,
        'is_in_progress': 0,
        'priority_order': 3,
        'dayFechaCreacion': '2026-03-03T09:00:00',
        'dayFechaModificacion': '2026-03-10T10:30:00',
        'sync_status': 'synced',
        'updated_at': now,
      },
      {
        'codAnaResActividad': 404,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 201,
        'codAnaResFase': 301,
        'codAnaresArea': '1',
        'desFrente': 'Torre A - Frente Norte de obra',
        'desFase': 'Estructuras y concreto armado',
        'desActividad': 'Instalacion de tuberia',
        'desRestriccion': 'Instalacion de tuberia completada.',
        'codTipoRestriccion': 2,
        'desTipoRestriccion': 'Materiales',
        'dayFechaRequerida': '2026-03-08',
        'idUsuarioResponsable': 8,
        'desResponsable': 'Juan Perez',
        'codEstadoActividad': 'completed',
        'desEstadoActividad': 'Completado',
        'colorEstado': '#1B8E5A',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 1,
        'is_overdue': 0,
        'is_due_today': 0,
        'is_pending': 0,
        'is_in_progress': 0,
        'priority_order': 5,
        'dayFechaCreacion': '2026-03-04T08:00:00',
        'dayFechaModificacion': '2026-03-08T10:30:00',
        'sync_status': 'synced',
        'updated_at': now,
      },
      {
        'codAnaResActividad': 405,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 202,
        'codAnaResFase': 302,
        'codAnaresArea': '2',
        'desFrente': 'Sotano 1',
        'desFase': 'Instalaciones sanitarias',
        'desActividad': 'Validacion de planos',
        'desRestriccion': 'Validacion de planos completada.',
        'codTipoRestriccion': 3,
        'desTipoRestriccion': 'Planos',
        'dayFechaRequerida': '2026-03-07',
        'idUsuarioResponsable': 9,
        'desResponsable': 'Maria Torres',
        'codEstadoActividad': 'completed',
        'desEstadoActividad': 'Completado',
        'colorEstado': '#1B8E5A',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 1,
        'is_overdue': 0,
        'is_due_today': 0,
        'is_pending': 0,
        'is_in_progress': 0,
        'priority_order': 5,
        'dayFechaCreacion': '2026-03-05T08:00:00',
        'dayFechaModificacion': '2026-03-07T16:00:00',
        'sync_status': 'synced',
        'updated_at': now,
      },
      {
        'codAnaResActividad': 406,
        'codProyecto': 101,
        'codAnaRes': 1,
        'codAnaResFrente': 203,
        'codAnaResFase': 303,
        'codAnaresArea': '3',
        'desFrente': 'Lobby principal',
        'desFase': 'Acabados interiores y carpinteria',
        'desActividad': 'Entrega de materiales',
        'desRestriccion': 'Entrega de materiales completada.',
        'codTipoRestriccion': 2,
        'desTipoRestriccion': 'Materiales',
        'dayFechaRequerida': '2026-03-05',
        'idUsuarioResponsable': 10,
        'desResponsable': 'Carlos Diaz',
        'codEstadoActividad': 'completed',
        'desEstadoActividad': 'Completado',
        'colorEstado': '#1B8E5A',
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'is_completed': 1,
        'is_overdue': 0,
        'is_due_today': 0,
        'is_pending': 0,
        'is_in_progress': 0,
        'priority_order': 5,
        'dayFechaCreacion': '2026-03-06T08:00:00',
        'dayFechaModificacion': '2026-03-05T16:00:00',
        'sync_status': 'synced',
        'updated_at': now,
      },
    ];
    for (final row in restrictions) {
      batch.insert('anares_restriction', row);
    }

    batch.insert('app_settings', {
      'key': 'current_project_id',
      'value': '101',
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('app_settings', {
      'key': 'keep_signed_in',
      'value': '1',
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await batch.commit(noResult: true);
    await _seedControlHitosCatalogs(db, now);
    await _seedControlHitos(db, now);
    await _ensureDefaultSettings(db, now);
    await _refreshProjectSummary(db, 101);
  }

  Future<void> _seedControlHitosCatalogs(Database db, String now) async {
    final internalStatusCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM conhit_statusinterno'),
        ) ??
        0;
    final contractualStatusCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM conhit_statuscontractual'),
        ) ??
        0;
    final batch = db.batch();

    if (internalStatusCount == 0) {
      batch.insert('conhit_statusinterno', {
        'codEstado': '1',
        'desEstado': 'En progreso',
        'desColor': '#F0A11E',
        'desIcono': 'timelapse',
        'orden': 1,
        'updated_at': now,
      });
      batch.insert('conhit_statusinterno', {
        'codEstado': '2',
        'desEstado': 'Retrasado',
        'desColor': '#D64545',
        'desIcono': 'warning',
        'orden': 2,
        'updated_at': now,
      });
      batch.insert('conhit_statusinterno', {
        'codEstado': '3',
        'desEstado': 'Completado',
        'desColor': '#1B8E5A',
        'desIcono': 'check_circle',
        'orden': 3,
        'updated_at': now,
      });
    }

    if (contractualStatusCount == 0) {
      batch.insert('conhit_statuscontractual', {
        'codEstado': '1',
        'desEstado': 'En progreso',
        'desColor': '#F0A11E',
        'desIcono': 'timelapse',
        'orden': 1,
        'updated_at': now,
      });
      batch.insert('conhit_statuscontractual', {
        'codEstado': '2',
        'desEstado': 'Retrasado',
        'desColor': '#D64545',
        'desIcono': 'warning',
        'orden': 2,
        'updated_at': now,
      });
      batch.insert('conhit_statuscontractual', {
        'codEstado': '3',
        'desEstado': 'Completado',
        'desColor': '#1B8E5A',
        'desIcono': 'check_circle',
        'orden': 3,
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<void> _seedControlHitos(Database db, String now) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM conhit_detallehitos'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    batch.insert('conhit_controlhitos', {
      'codConHit': 2026031701,
      'codEstado': 1,
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'Sistema',
      'dayFechaModificacion': now,
      'desUsuarioModificacion': 'Sistema',
      'codProyecto': 101,
      'sync_status': 'synced',
      'updated_at': now,
    });
    batch.insert('conhit_general', {
      'codConHitGeneral': 20260317011,
      'codConHit': 2026031701,
      'codProyecto': 101,
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'Sistema',
      'dayFechaModificacion': now,
      'desUsuarioModificacion': 'Sistema',
      'numDiasPlazoTotal': 240,
      'mntTotal': 1250000,
      'numDias': 240,
      'codEstado': 1,
      'dayFechaInicioContractual': '2026-01-10',
      'flgAplicaHitoGeneral': 1,
      'sync_status': 'synced',
      'updated_at': now,
    });

    final milestones = [
      {
        'codConHitDetalleHitos': 202603170101,
        'codConHit': 2026031701,
        'codProyecto': 101,
        'codConHitGeneral': 20260317011,
        'NumOrden': 1,
        'desDescripcion': 'Entrega de expediente tecnico definitivo',
        'codTipoHito': 1,
        'codTipoClasificacion': 1,
        'numplazo': 10,
        'porPenalidad': 0.0125,
        'dayFechaContractual': '2026-03-05',
        'dayFechaMeta': '2026-03-12',
        'numCantAmpContractual': 0,
        'numCantAmpMeta': 0,
        'dayFechaReal': '2026-03-11',
        'desLinkDocuCierre': 'expediente-tecnico-vfinal.pdf',
        'codEstadoContractual': 3,
        'codEstadoInternos': '3',
        'mntPealidad': 1250.0,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'Sistema',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'Sistema',
        'dayFechaContractualAmp': null,
        'dayFechaMetaAmp': null,
        'sync_status': 'synced',
        'updated_at': now,
      },
      {
        'codConHitDetalleHitos': 202603170102,
        'codConHit': 2026031701,
        'codProyecto': 101,
        'codConHitGeneral': 20260317011,
        'NumOrden': 2,
        'desDescripcion': 'Inicio de montaje electromecanico de nave principal',
        'codTipoHito': 2,
        'codTipoClasificacion': 2,
        'numplazo': 15,
        'porPenalidad': 0.015,
        'dayFechaContractual': '2026-03-09',
        'dayFechaMeta': '2026-03-15',
        'numCantAmpContractual': 1,
        'numCantAmpMeta': 1,
        'dayFechaReal': null,
        'desLinkDocuCierre': null,
        'codEstadoContractual': 1,
        'codEstadoInternos': '1',
        'mntPealidad': 2480.0,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'Sistema',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'Sistema',
        'dayFechaContractualAmp': '2026-03-18',
        'dayFechaMetaAmp': '2026-03-18',
        'sync_status': 'pending',
        'updated_at': now,
      },
      {
        'codConHitDetalleHitos': 202603170103,
        'codConHit': 2026031701,
        'codProyecto': 101,
        'codConHitGeneral': 20260317011,
        'NumOrden': 3,
        'desDescripcion': 'Pruebas SAT del sistema de climatizacion',
        'codTipoHito': 3,
        'codTipoClasificacion': 3,
        'numplazo': 8,
        'porPenalidad': 0.02,
        'dayFechaContractual': '2026-03-08',
        'dayFechaMeta': '2026-03-10',
        'numCantAmpContractual': 0,
        'numCantAmpMeta': 0,
        'dayFechaReal': null,
        'desLinkDocuCierre': null,
        'codEstadoContractual': 2,
        'codEstadoInternos': '2',
        'mntPealidad': 3900.0,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'Sistema',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'Sistema',
        'dayFechaContractualAmp': null,
        'dayFechaMetaAmp': null,
        'sync_status': 'failed',
        'updated_at': now,
      },
    ];
    for (final row in milestones) {
      batch.insert('conhit_detallehitos', row);
    }

    batch.insert('conhit_archivosfechareal', {
      'codConhitArchivosFechaReal': 2026031701001,
      'codConHitDetalleHitos': 202603170101,
      'desNombreArchivo': 'expediente-tecnico-vfinal.pdf',
      'desRutaArchivo': 'expediente-tecnico-vfinal.pdf',
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'Ana Romero',
      'dayFechaModificacion': now,
      'desUsuarioModifcacion': 'Ana Romero',
      'sync_status': 'synced',
      'updated_at': now,
    });

    batch.insert('conthit_detallehitosamp', {
      'codConHitDetalleHitosAmp': 2026031702001,
      'codConHitDetalleHitos': 202603170102,
      'desMotivo': 'Ampliacion por reprogramacion de suministro',
      'dayFechaMeta': '2026-03-18',
      'dayFechaContractual': '2026-03-18',
      'desLinklDocuAmp': 'sustento-ampliacion-logistica.pdf',
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'Jefatura de Proyecto',
      'dayFechaModificacion': now,
      'desUsuarioModificacion': 'Jefatura de Proyecto',
      'desTipoFecha': 'both',
      'sync_status': 'synced',
      'updated_at': now,
    });

    await batch.commit(noResult: true);
  }

  Future<void> _seedAvanceGraficoCatalogs(Database db, String now) async {
    final estadosCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM avagra_estados'),
        ) ??
        0;
    final formaCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM avagra_forma'),
        ) ??
        0;
    final sentidoCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM avagra_sentidohorario'),
        ) ??
        0;
    final ladoCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM avagra_tipolado'),
        ) ??
        0;
    final batch = db.batch();

    if (estadosCount == 0) {
      for (final row in const [
        {
          'codEstado': 1,
          'desEstado': 'No Aplica',
          'desFase': 'FaseUno_Posiciones',
          'codColor': '#000000',
          'desColor': 'negro',
        },
        {
          'codEstado': 2,
          'desEstado': 'Completado',
          'desFase': 'FaseUno_Posiciones',
          'codColor': '#6ECC77',
          'desColor': 'verde claro',
        },
        {
          'codEstado': 4,
          'desEstado': 'Pendiente',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#BEBEB9',
          'desColor': 'gris',
        },
        {
          'codEstado': 5,
          'desEstado': 'En proceso',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#FFB601',
          'desColor': 'amarillo',
        },
        {
          'codEstado': 6,
          'desEstado': 'Completado',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#6ECC77',
          'desColor': 'verde claro',
        },
        {
          'codEstado': 7,
          'desEstado': 'Aprobado por Calidad',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#015C1E',
          'desColor': 'verde oscuro',
        },
        {
          'codEstado': 8,
          'desEstado': 'Programado Sem. Actual',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#0190DC',
          'desColor': 'celeste',
        },
        {
          'codEstado': 11,
          'desEstado': 'Completado',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#6ECC77',
          'desColor': 'verde claro',
        },
        {
          'codEstado': 12,
          'desEstado': 'Pendiente',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#BEBEB9',
          'desColor': 'gris',
        },
        {
          'codEstado': 13,
          'desEstado': 'En proceso',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#FFB601',
          'desColor': 'amarillo',
        },
        {
          'codEstado': 14,
          'desEstado': 'Aprobado por Calidad',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#015C1E',
          'desColor': 'verde oscuro',
        },
        {
          'codEstado': 15,
          'desEstado': 'Programado Sem. Actual',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#0190DC',
          'desColor': 'celeste',
        },
        {
          'codEstado': 16,
          'desEstado': 'No Aplica',
          'desFase': 'FaseTres_ActividadesXSectores',
          'codColor': '#000000',
          'desColor': 'negro',
        },
        {
          'codEstado': 17,
          'desEstado': 'Pendiente',
          'desFase': 'FaseUno_Posiciones',
          'codColor': '#BEBEB9',
          'desColor': 'gris',
        },
        {
          'codEstado': 18,
          'desEstado': 'Programado Sem. Actual',
          'desFase': 'FaseUno_Posiciones',
          'codColor': '#0190DC',
          'desColor': 'celeste',
        },
        {
          'codEstado': 19,
          'desEstado': 'No Aplica',
          'desFase': 'FaseDos_Cuadros',
          'codColor': '#000000',
          'desColor': 'negro',
        },
      ]) {
        batch.insert('avagra_estados', row);
      }
    }

    if (formaCount == 0) {
      batch.insert('avagra_forma', {
        'CodForma': 1,
        'DesForma': 'Rectangulo Vertical',
        'DesAbrev': 'RV',
        'DesIcon': 'crop_portrait',
      });
      batch.insert('avagra_forma', {
        'CodForma': 2,
        'DesForma': 'Rectangulo Horizontal',
        'DesAbrev': 'RH',
        'DesIcon': 'crop_landscape',
      });
      batch.insert('avagra_forma', {
        'CodForma': 3,
        'DesForma': 'Cuadrado',
        'DesAbrev': 'CU',
        'DesIcon': 'square_rounded',
      });
    }
    if (sentidoCount == 0) {
      batch.insert('avagra_sentidohorario', {
        'CodSentido': 1,
        'DesSentido': 'Horario',
        'DesAbrev': 'H',
        'DesIcon': 'rotate_right',
      });
      batch.insert('avagra_sentidohorario', {
        'CodSentido': 2,
        'DesSentido': 'Antihorario',
        'DesAbrev': 'AH',
        'DesIcon': 'rotate_left',
      });
    }
    if (ladoCount == 0) {
      batch.insert('avagra_tipolado', {
        'CodTipoLado': 1,
        'DesLado': 'Superior',
        'DesAbrev': 'SUP',
        'DesIcon': 'north',
      });
      batch.insert('avagra_tipolado', {
        'CodTipoLado': 2,
        'DesLado': 'Inferior',
        'DesAbrev': 'INF',
        'DesIcon': 'south',
      });
      batch.insert('avagra_tipolado', {
        'CodTipoLado': 3,
        'DesLado': 'Izquierda',
        'DesAbrev': 'IZQ',
        'DesIcon': 'west',
      });
      batch.insert('avagra_tipolado', {
        'CodTipoLado': 4,
        'DesLado': 'Derecha',
        'DesAbrev': 'DER',
        'DesIcon': 'east',
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedAvanceGrafico(Database db, String now) async {
    // Solo seed de cabeceras de modulo/fases. No se generan detalles por fase.
    await db.execute('PRAGMA foreign_keys = OFF');
    final batch = db.batch();

    for (final row in const [
      {'codAvaGrafico': 7101, 'codProyecto': 101, 'vistaSeleccionada': 0},
      {'codAvaGrafico': 7102, 'codProyecto': 102, 'vistaSeleccionada': 1},
      {'codAvaGrafico': 7103, 'codProyecto': 103, 'vistaSeleccionada': 0},
    ]) {
      batch.insert('avagra_avancegrafico', {
        ...row,
        'codEstado': 1,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'Sistema',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in const [
      {'codFaseUno': 7111, 'codProyecto': 101, 'codAvaGrafico': 7101},
      {'codFaseUno': 7211, 'codProyecto': 102, 'codAvaGrafico': 7102},
      {'codFaseUno': 7311, 'codProyecto': 103, 'codAvaGrafico': 7103},
    ]) {
      batch.insert('avagra_faseuno', {
        ...row,
        'DesFaseUno': 'Configuracion base de Fase 1',
        'Comentarios': 'Cabecera inicial de fase',
        'desResOrdenTipoLados': '1-4-2-3',
        'CodForma': 2,
        'CodSentido': 1,
        'flgNivelesGlobales': 0,
        'numNivelesGlobales': 0,
        'dayFechaCreacion': now,
        'codUsuarioCreacion': 'Sistema',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'Sistema',
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 5,
        'auto_generate_pdf_hours': '18:00',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in const [
      {'codFaseDos': 7121, 'codProyecto': 101, 'codAvaGrafico': 7101},
      {'codFaseDos': 7221, 'codProyecto': 102, 'codAvaGrafico': 7102},
      {'codFaseDos': 7321, 'codProyecto': 103, 'codAvaGrafico': 7103},
    ]) {
      batch.insert('avagra_fasedos', {
        ...row,
        'desFaseDos': 'Control inicial Fase 2',
        'desComentarios': 'Cabecera inicial de fase',
        'flgPisosUniformes': 0,
        'numPisosUniformes': 0,
        'dayFechaCreacion': now,
        'dayFechaModificacion': now,
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 5,
        'auto_generate_pdf_hours': '18:00',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final row in const [
      {'codFaseTres': 7131, 'codProyecto': 101, 'codAvaGrafico': 7101},
      {'codFaseTres': 7231, 'codProyecto': 102, 'codAvaGrafico': 7102},
      {'codFaseTres': 7331, 'codProyecto': 103, 'codAvaGrafico': 7103},
    ]) {
      batch.insert('avagra_fasetres', {
        ...row,
        'desFaseTres': 'Detalle por piso, sector y actividad',
        'desComentarios': 'Cabecera inicial de fase',
        'numPisos': 0,
        'numSectores': 0,
        'numActividades': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
    await db.execute('PRAGMA foreign_keys = ON');

    final projectRows = await db.query(
      'projects_project',
      columns: ['codProyecto'],
      where: 'codProyecto IS NOT NULL',
      orderBy: 'codProyecto ASC',
    );
    final excludedProjectId = projectRows.isEmpty
        ? null
        : projectRows.last['codProyecto'] as int?;
    for (final row in projectRows) {
      final projectId = row['codProyecto'] as int?;
      if (projectId == null) continue;
      if (excludedProjectId != null && projectId == excludedProjectId) continue;
      await _seedAvanceGraficoForProject(db, now, projectId);
    }
    if (excludedProjectId != null) {
      await _clearAvanceGraficoForProject(db, excludedProjectId);
    }
  }

  Future<void> _seedAvanceGraficoForProject(
    Database db,
    String now,
    int projectId,
  ) async {
    final moduleRows = await db.query(
      'avagra_avancegrafico',
      columns: ['codAvaGrafico'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    final moduleId =
        (moduleRows.isNotEmpty
            ? moduleRows.first['codAvaGrafico'] as int?
            : null) ??
        (900000 + projectId);
    final phase1Exists =
        (Sqflite.firstIntValue(
              await db.rawQuery(
                '''
                SELECT COUNT(*) FROM avagra_faseuno
                WHERE codProyecto = ? AND codAvaGrafico = ?
                ''',
                [projectId, moduleId],
              ),
            ) ??
            0) >
        0;
    final phase2Exists =
        (Sqflite.firstIntValue(
              await db.rawQuery(
                '''
                SELECT COUNT(*) FROM avagra_fasedos
                WHERE codProyecto = ? AND codAvaGrafico = ?
                ''',
                [projectId, moduleId],
              ),
            ) ??
            0) >
        0;
    final phase3Exists =
        (Sqflite.firstIntValue(
              await db.rawQuery(
                '''
                SELECT COUNT(*) FROM avagra_fasetres
                WHERE codProyecto = ? AND codAvaGrafico = ?
                ''',
                [projectId, moduleId],
              ),
            ) ??
            0) >
        0;
    final phase1Id = 910000 + projectId;
    final phase2Id = 920000 + projectId;
    final phase3Id = 930000 + projectId;

    final batch = db.batch();
    batch.insert('avagra_avancegrafico', {
      'codAvaGrafico': moduleId,
      'codProyecto': projectId,
      'codEstado': 1,
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'Sistema',
      'vistaSeleccionada': projectId.isEven ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (!phase1Exists) {
      batch.insert('avagra_faseuno', {
        'codFaseUno': phase1Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'DesFaseUno': 'Configuracion base de Fase 1',
        'Comentarios':
            'Generado localmente para visualizacion inicial del modulo.',
        'desResOrdenTipoLados': '1-4-2-3',
        'CodForma': projectId % 3 == 0 ? 3 : 2,
        'CodSentido': projectId.isEven ? 2 : 1,
        'flgNivelesGlobales': 0,
        'numNivelesGlobales': 0,
        'dayFechaCreacion': now,
        'codUsuarioCreacion': 'Sistema',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'Sistema',
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 5,
        'auto_generate_pdf_hours': '18:00',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (!phase2Exists) {
      batch.insert('avagra_fasedos', {
        'codFaseDos': phase2Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'desFaseDos': 'Matriz inicial de Fase 2',
        'desComentarios': 'Cabecera inicial de fase',
        'flgPisosUniformes': 0,
        'numPisosUniformes': 0,
        'dayFechaCreacion': now,
        'dayFechaModificacion': now,
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 3,
        'auto_generate_pdf_hours': '17:00',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (!phase3Exists) {
      batch.insert('avagra_fasetres', {
        'codFaseTres': phase3Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'desFaseTres': 'Detalle inicial de Fase 3',
        'desComentarios': 'Cabecera inicial de fase',
        'numPisos': 0,
        'numSectores': 0,
        'numActividades': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _clearAvanceGraficoForProject(Database db, int projectId) async {
    final phase1Sections = await db.query(
      'avagra_secciones',
      columns: ['codSecciones'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    final sectionIds = phase1Sections
        .map((row) => row['codSecciones'] as int?)
        .whereType<int>()
        .toList();
    await _deleteWhereIn(
      db,
      table: 'avagra_posiciones',
      column: 'codSecciones',
      ids: sectionIds,
    );
    await db.delete(
      'avagra_faseunodocumentos',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_secciones',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_faseuno',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );

    final phase2Activities = await db.query(
      'avagra_actividades',
      columns: ['codActividades'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    final phase2ActivityIds = phase2Activities
        .map((row) => row['codActividades'] as int?)
        .whereType<int>()
        .toList();
    await _deleteWhereIn(
      db,
      table: 'avagra_cuadros',
      column: 'codActividades',
      ids: phase2ActivityIds,
    );
    await db.delete(
      'avagra_fotos',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_actividades',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_fasedos',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );

    final floorRows = await db.query(
      'avagra_pisos',
      columns: ['codPiso'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    final floorIds = floorRows
        .map((row) => row['codPiso'] as int?)
        .whereType<int>()
        .toList();
    final sectorFloorRows = await _queryWhereIn(
      db,
      table: 'avagra_sectoresxpisos',
      columns: ['codSectorxPiso'],
      column: 'codPiso',
      ids: floorIds,
    );
    final sectorFloorIds = sectorFloorRows
        .map((row) => row['codSectorxPiso'] as int?)
        .whereType<int>()
        .toList();
    final activityFloorRows = await _queryWhereIn(
      db,
      table: 'avagra_actividadxpisos',
      columns: ['codActividadxPiso'],
      column: 'codPiso',
      ids: floorIds,
    );
    final activityFloorIds = activityFloorRows
        .map((row) => row['codActividadxPiso'] as int?)
        .whereType<int>()
        .toList();
    await _deleteWhereIn(
      db,
      table: 'avagra_actividadxsectorxpisos',
      column: 'codSectorxPiso',
      ids: sectorFloorIds,
    );
    await _deleteWhereIn(
      db,
      table: 'avagra_actividadxsectorxpisos',
      column: 'codActividadxPiso',
      ids: activityFloorIds,
    );
    await _deleteWhereIn(
      db,
      table: 'avagra_actividadxpisos',
      column: 'codActividadxPiso',
      ids: activityFloorIds,
    );
    await _deleteWhereIn(
      db,
      table: 'avagra_sectoresxpisos',
      column: 'codSectorxPiso',
      ids: sectorFloorIds,
    );
    await _deleteWhereIn(
      db,
      table: 'avagra_pisos',
      column: 'codPiso',
      ids: floorIds,
    );
    await db.delete(
      'avagra_actividad',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_sectores',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_fasetres',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );

    await db.delete(
      'avagra_integrantes',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await db.delete(
      'avagra_avancegrafico',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
  }

  Future<List<Map<String, Object?>>> _queryWhereIn(
    Database db, {
    required String table,
    required List<String> columns,
    required String column,
    required List<int> ids,
  }) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    return db.query(
      table,
      columns: columns,
      where: '$column IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> _deleteWhereIn(
    Database db, {
    required String table,
    required String column,
    required List<int> ids,
  }) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.delete(table, where: '$column IN ($placeholders)', whereArgs: ids);
  }

  // ignore: unused_element
  List<Map<String, Object?>> _buildAvagraPositionSeed(String now) {
    final rows = <Map<String, Object?>>[];
    var id = 7111000;
    for (var level = 1; level <= 3; level++) {
      for (var bay = 1; bay <= 4; bay++) {
        rows.add({
          'codPosition': ++id,
          'codSecciones': 711101,
          'desNumeracion': 'N$level-$bay',
          'numNivel': level,
          'numPanio': bay,
          'desPosicion': 'Panel N$level-$bay',
          'desAbrev': 'P$bay',
          'codEstado': bay == 4 ? 3 : (level == 1 ? 2 : 1),
          'codUsuarioCreacion': 'Sistema',
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 'Sistema',
          'dayFechaModificacion': now,
        });
      }
    }
    for (var level = 1; level <= 2; level++) {
      for (var bay = 1; bay <= 3; bay++) {
        rows.add({
          'codPosition': ++id,
          'codSecciones': 711102,
          'desNumeracion': 'E$level-$bay',
          'numNivel': level,
          'numPanio': bay,
          'desPosicion': 'Panel E$level-$bay',
          'desAbrev': 'E$bay',
          'codEstado': (level == 2 && bay == 3) ? 4 : (bay == 1 ? 2 : 1),
          'codUsuarioCreacion': 'Sistema',
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 'Sistema',
          'dayFechaModificacion': now,
        });
      }
    }
    id = 7211000;
    for (var level = 1; level <= 2; level++) {
      for (var bay = 1; bay <= 3; bay++) {
        rows.add({
          'codPosition': ++id,
          'codSecciones': 721101,
          'desNumeracion': 'A$level-$bay',
          'numNivel': level,
          'numPanio': bay,
          'desPosicion': 'Torre A$level-$bay',
          'desAbrev': 'A$bay',
          'codEstado': bay == 3 ? 3 : 2,
          'codUsuarioCreacion': 'Sistema',
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 'Sistema',
          'dayFechaModificacion': now,
        });
      }
    }
    id = 7311000;
    for (var level = 1; level <= 3; level++) {
      for (var bay = 1; bay <= 3; bay++) {
        rows.add({
          'codPosition': ++id,
          'codSecciones': 731101,
          'desNumeracion': 'C$level-$bay',
          'numNivel': level,
          'numPanio': bay,
          'desPosicion': 'Central C$level-$bay',
          'desAbrev': 'C$bay',
          'codEstado': level == 3 ? 1 : 2,
          'codUsuarioCreacion': 'Sistema',
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 'Sistema',
          'dayFechaModificacion': now,
        });
      }
    }
    return rows;
  }

  // ignore: unused_element
  List<Map<String, Object?>> _buildAvagraCuadroSeed(String now) {
    final rows = <Map<String, Object?>>[];
    var id = 7121000;
    var order = 0;
    for (var floor = 5; floor >= -1; floor--) {
      for (var sector = 1; sector <= 4; sector++) {
        rows.add({
          'codCuadros': ++id,
          'codActividades': 712101,
          'numOrden': ++order,
          'numPiso': floor,
          'numSector': sector,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
          'codEstado': floor >= 4
              ? 7
              : (floor >= 2 ? 6 : (sector == 4 ? 9 : 5)),
        });
      }
    }
    for (var floor = 4; floor >= 1; floor--) {
      for (var sector = 1; sector <= 3; sector++) {
        rows.add({
          'codCuadros': ++id,
          'codActividades': 712102,
          'numOrden': ++order,
          'numPiso': floor,
          'numSector': sector,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
          'codEstado': sector == 3 ? 8 : 7,
        });
      }
    }
    id = 7221000;
    order = 0;
    for (var floor = 6; floor >= 1; floor--) {
      for (var sector = 1; sector <= 3; sector++) {
        rows.add({
          'codCuadros': ++id,
          'codActividades': 722101,
          'numOrden': ++order,
          'numPiso': floor,
          'numSector': sector,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
          'codEstado': sector == 1 ? 8 : 7,
        });
      }
    }
    id = 7321000;
    order = 0;
    for (var floor = 4; floor >= -1; floor--) {
      for (var sector = 1; sector <= 4; sector++) {
        rows.add({
          'codCuadros': ++id,
          'codActividades': 732101,
          'numOrden': ++order,
          'numPiso': floor,
          'numSector': sector,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
          'codEstado': floor <= 0 ? 5 : (sector == 4 ? 10 : 6),
        });
      }
    }
    return rows;
  }

  // ignore: unused_element
  List<Map<String, Object?>> _buildAvagraPhase3Seed(String now) {
    final rows = <Map<String, Object?>>[];

    for (final piso in [
      {
        '_table': 'avagra_pisos',
        'codPiso': 713101,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desAbrev': 'P5',
        'desNombre': 'Piso 5',
        'numOrden': 5,
        'desLinkPlano': 'p5-plan.png',
        'desNombrePlano': 'Plano Piso 5',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_pisos',
        'codPiso': 713102,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desAbrev': 'P4',
        'desNombre': 'Piso 4',
        'numOrden': 4,
        'desLinkPlano': 'p4-plan.png',
        'desNombrePlano': 'Plano Piso 4',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_pisos',
        'codPiso': 723101,
        'codFaseTres': 7231,
        'codProyecto': 102,
        'codAvaGrafico': 7102,
        'desAbrev': 'P6',
        'desNombre': 'Piso 6',
        'numOrden': 6,
        'desLinkPlano': 'p6-plan.png',
        'desNombrePlano': 'Plano Piso 6',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_pisos',
        'codPiso': 733101,
        'codFaseTres': 7331,
        'codProyecto': 103,
        'codAvaGrafico': 7103,
        'desAbrev': 'N1',
        'desNombre': 'Nivel 1',
        'numOrden': 1,
        'desLinkPlano': 'n1-plan.png',
        'desNombrePlano': 'Plano Nivel 1',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(piso));
    }

    for (final sector in [
      {
        '_table': 'avagra_sectores',
        'codSector': 713201,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desNombre': 'Sector A',
        'desDescripcion': 'Frente norte',
        'jsonPosicionamientoPlano': '{"x":0.1,"y":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectores',
        'codSector': 713202,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desNombre': 'Sector B',
        'desDescripcion': 'Nucleo central',
        'jsonPosicionamientoPlano': '{"x":0.4,"y":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectores',
        'codSector': 723201,
        'codFaseTres': 7231,
        'codProyecto': 102,
        'codAvaGrafico': 7102,
        'desNombre': 'Ala Este',
        'desDescripcion': 'Bloque oficinas',
        'jsonPosicionamientoPlano': '{"x":0.2,"y":0.3}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectores',
        'codSector': 733201,
        'codFaseTres': 7331,
        'codProyecto': 103,
        'codAvaGrafico': 7103,
        'desNombre': 'Rack 1',
        'desDescripcion': 'Area de montaje',
        'jsonPosicionamientoPlano': '{"x":0.3,"y":0.5}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(sector));
    }

    for (final sectorXPiso in [
      {
        '_table': 'avagra_sectoresxpisos',
        'codSectorxPiso': 713301,
        'codPiso': 713101,
        'codSector': 713201,
        'desNombre': 'Sector A P5',
        'desDescripcion': 'Ala norte piso 5',
        'codEstado': 12,
        'numPorcentajeCompletados': 55.0,
        'numPorcentajeAprobadosCalidad': 20.0,
        'jsonPosicionamientoPlano': '{"x":0.1,"y":0.2,"w":0.2,"h":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectoresxpisos',
        'codSectorxPiso': 713302,
        'codPiso': 713101,
        'codSector': 713202,
        'desNombre': 'Sector B P5',
        'desDescripcion': 'Nucleo piso 5',
        'codEstado': 13,
        'numPorcentajeCompletados': 82.0,
        'numPorcentajeAprobadosCalidad': 40.0,
        'jsonPosicionamientoPlano': '{"x":0.45,"y":0.2,"w":0.2,"h":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectoresxpisos',
        'codSectorxPiso': 713303,
        'codPiso': 713102,
        'codSector': 713201,
        'desNombre': 'Sector A P4',
        'desDescripcion': 'Ala norte piso 4',
        'codEstado': 14,
        'numPorcentajeCompletados': 100.0,
        'numPorcentajeAprobadosCalidad': 76.0,
        'jsonPosicionamientoPlano': '{"x":0.1,"y":0.2,"w":0.2,"h":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectoresxpisos',
        'codSectorxPiso': 723301,
        'codPiso': 723101,
        'codSector': 723201,
        'desNombre': 'Ala Este P6',
        'desDescripcion': 'Nivel premium',
        'codEstado': 14,
        'numPorcentajeCompletados': 90.0,
        'numPorcentajeAprobadosCalidad': 65.0,
        'jsonPosicionamientoPlano': '{"x":0.2,"y":0.3,"w":0.3,"h":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_sectoresxpisos',
        'codSectorxPiso': 733301,
        'codPiso': 733101,
        'codSector': 733201,
        'desNombre': 'Rack 1 N1',
        'desDescripcion': 'Montaje inicial',
        'codEstado': 12,
        'numPorcentajeCompletados': 35.0,
        'numPorcentajeAprobadosCalidad': 5.0,
        'jsonPosicionamientoPlano': '{"x":0.3,"y":0.5,"w":0.25,"h":0.2}',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(sectorXPiso));
    }

    for (final actividad in [
      {
        '_table': 'avagra_actividad',
        'codActividad': 713401,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desNombre': 'Pintura base',
        'desDescripcion': 'Aplicacion base por sector',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividad',
        'codActividad': 713402,
        'codFaseTres': 7131,
        'codProyecto': 101,
        'codAvaGrafico': 7101,
        'desNombre': 'Sellado',
        'desDescripcion': 'Detalle de juntas',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividad',
        'codActividad': 723401,
        'codFaseTres': 7231,
        'codProyecto': 102,
        'codAvaGrafico': 7102,
        'desNombre': 'Drywall final',
        'desDescripcion': 'Remate final',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividad',
        'codActividad': 733401,
        'codFaseTres': 7331,
        'codProyecto': 103,
        'codAvaGrafico': 7103,
        'desNombre': 'Montaje mecanico',
        'desDescripcion': 'Alineamiento y torque',
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(actividad));
    }

    for (final actividadXPiso in [
      {
        '_table': 'avagra_actividadxpisos',
        'codActividadxPiso': 713501,
        'codActividad': 713401,
        'codPiso': 713101,
        'desAbrev': 'PIN',
        'desDescripcion': 'Pintura base P5',
        'codEstado': 12,
        'numOrden': 1,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxpisos',
        'codActividadxPiso': 713502,
        'codActividad': 713402,
        'codPiso': 713101,
        'desAbrev': 'SEL',
        'desDescripcion': 'Sellado P5',
        'codEstado': 13,
        'numOrden': 2,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxpisos',
        'codActividadxPiso': 713503,
        'codActividad': 713401,
        'codPiso': 713102,
        'desAbrev': 'PIN',
        'desDescripcion': 'Pintura base P4',
        'codEstado': 14,
        'numOrden': 1,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxpisos',
        'codActividadxPiso': 723501,
        'codActividad': 723401,
        'codPiso': 723101,
        'desAbrev': 'DRY',
        'desDescripcion': 'Drywall P6',
        'codEstado': 14,
        'numOrden': 1,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxpisos',
        'codActividadxPiso': 733501,
        'codActividad': 733401,
        'codPiso': 733101,
        'desAbrev': 'MM',
        'desDescripcion': 'Montaje N1',
        'codEstado': 12,
        'numOrden': 1,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(actividadXPiso));
    }

    for (final detalle in [
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 713601,
        'codActividadxPiso': 713501,
        'codSectorxPiso': 713301,
        'codEstado': 12,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 713602,
        'codActividadxPiso': 713501,
        'codSectorxPiso': 713302,
        'codEstado': 13,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 713603,
        'codActividadxPiso': 713502,
        'codSectorxPiso': 713301,
        'codEstado': 11,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 713604,
        'codActividadxPiso': 713502,
        'codSectorxPiso': 713302,
        'codEstado': 14,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 713605,
        'codActividadxPiso': 713503,
        'codSectorxPiso': 713303,
        'codEstado': 14,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 723601,
        'codActividadxPiso': 723501,
        'codSectorxPiso': 723301,
        'codEstado': 14,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      {
        '_table': 'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso': 733601,
        'codActividadxPiso': 733501,
        'codSectorxPiso': 733301,
        'codEstado': 12,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
    ]) {
      rows.add(Map<String, Object?>.from(detalle));
    }

    return rows;
  }

  Future<void> _seedAreaCatalog(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM projects_area_member'),
        ) ??
        0;
    if (count == 0) {
      final batch = db.batch();
      for (final row in _areaSeedRows()) {
        batch.insert(
          'projects_area_member',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _ensureDefaultSettings(Database db, String now) async {
    for (final entry in [
      const MapEntry('dark_mode', '0'),
      const MapEntry('offline_mode', '0'),
      const MapEntry('remote_sync_enabled', '1'),
      const MapEntry('device_linked', '0'),
      const MapEntry('device_binding_id', null),
      const MapEntry('device_binding_label', null),
      const MapEntry('device_binding_linked_at', null),
      const MapEntry('location_permission_requested', '0'),
      const MapEntry('location_permission_status', 'unknown'),
      const MapEntry('location_permission_requested_at', null),
      const MapEntry('last_sync_at', null),
      const MapEntry('last_sync_version', null),
      const MapEntry('last_daily_full_sync_business_date', null),
      const MapEntry('background_sync_in_progress', '0'),
      const MapEntry('remote_sync_lock_token', null),
      const MapEntry('remote_sync_lock_until', null),
      const MapEntry('remote_sync_lock_owner', null),
      const MapEntry('remote_sync_lock_source', null),
      const MapEntry('remote_sync_lock_acquired_at', null),
      const MapEntry('remote_sync_lock_last_heartbeat_at', null),
      const MapEntry('notifications_enabled', '1'),
      const MapEntry('notifications_module_restrictions', '1'),
      const MapEntry('notifications_module_actreu', '1'),
      const MapEntry('indicators_enabled', '1'),
      const MapEntry('indicators_module_restrictions', '1'),
      const MapEntry('indicators_module_hitos', '1'),
      const MapEntry('indicators_module_actreu', '1'),
    ]) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  List<Map<String, Object?>> _areaSeedRows() {
    return const [
      {'codArea': 1, 'desArea': 'Supervision'},
      {'codArea': 2, 'desArea': 'Planeamiento'},
      {'codArea': 3, 'desArea': 'Produccion'},
      {'codArea': 4, 'desArea': 'Logistica'},
    ];
  }

  Future<void> refreshProjectSummary(DatabaseExecutor db, int projectId) async {
    await _refreshProjectSummary(db, projectId);
  }

  Future<void> ensureAvanceGraficoDemoForProject(int projectId) async {
    // Deprecated: Avance Grafico se puebla unicamente desde sync pull remoto.
  }

  Future<void> _refreshProjectSummary(
    DatabaseExecutor db,
    int projectId,
  ) async {
    final row = (await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN is_overdue = 1 THEN 1 ELSE 0 END) AS overdue,
        SUM(CASE WHEN is_in_progress = 1 THEN 1 ELSE 0 END) AS in_progress,
        SUM(CASE WHEN is_pending = 1 THEN 1 ELSE 0 END) AS pending
      FROM anares_restriction
      WHERE codProyecto = ? AND IFNULL(codEstadoActividad, '') != '99'
      ''',
      [projectId],
    )).first;

    final total = (row['total'] as int?) ?? 0;
    final completed = (row['completed'] as int?) ?? 0;
    final overdue = (row['overdue'] as int?) ?? 0;
    final inProgress = (row['in_progress'] as int?) ?? 0;
    final pending = (row['pending'] as int?) ?? 0;
    final compliance = total == 0 ? 0.0 : completed / total;

    await db.insert('anares_summary', {
      'codProyecto': projectId,
      'totalRestrictions': total,
      'completedCount': completed,
      'overdueCount': overdue,
      'inProgressCount': inProgress,
      'pendingCount': pending,
      'compliancePercent': compliance,
      'updated_at': _limaNowIso8601(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
