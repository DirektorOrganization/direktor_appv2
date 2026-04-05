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
        await _ensureRestrictionAreaStructures(db);
        await _ensureControlHitosStructures(db);
        await _ensureModuleInsightsStructures(db);
        await _seed(db);
      },
      onOpen: (db) async {
        // Keep existing installs aligned with the latest SQLite schema additions.
        await _executeSchema(db);
        await _ensureAuthUserPasswordColumn(db);
        await _ensureRestrictionAreaStructures(db);
        await _ensureControlHitosStructures(db);
        await _ensureModuleInsightsStructures(db);
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conhit_detallehitos (
        codConHitDetalleHitos INTEGER PRIMARY KEY,
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
        'codTipoRestriccion': 1,
        'desTipoRestriccion': 'Permisos',
        'updated_at': now,
      },
      {
        'codTipoRestriccion': 2,
        'desTipoRestriccion': 'Materiales',
        'updated_at': now,
      },
      {
        'codTipoRestriccion': 3,
        'desTipoRestriccion': 'Planos',
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
