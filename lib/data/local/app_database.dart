import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'direktor_mobile_v2.db');

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
        await _seed(db);
      },
      onOpen: (db) async {
        await _ensureAuthUserPasswordColumn(db);
        await _ensureRestrictionAreaStructures(db);
        await _seed(db);
      },
    );
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

  Future<void> _ensureRestrictionAreaStructures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects_area_member (
        codArea INTEGER PRIMARY KEY,
        desArea TEXT,
        cod_Empresa INTEGER
      )
    ''');

    final columns = await db.rawQuery('PRAGMA table_info(anares_restriction)');
    final hasArea = columns.any((column) => column['name'] == 'codArea');
    if (!hasArea) {
      await db.execute('ALTER TABLE anares_restriction ADD COLUMN codArea TEXT');
    }
  }

  Future<void> _seed(Database db) async {
    final projectCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM projects_project'),
    );
    final now = DateTime.now().toIso8601String();

    if ((projectCount ?? 0) > 0) {
      await db.update(
        'auth_user',
        {
          'password': '123456',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [7],
      );
      await _seedAreaCatalog(db);
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
        'codArea': '2',
        'desFrente': 'Torre A - Frente Norte de obra',
        'desFase': 'Estructuras y concreto armado',
        'desActividad': 'Tramitar aprobacion municipal',
        'desRestriccion': 'Falta permiso municipal para liberar el frente y continuar con el avance programado.',
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
        'codArea': '4',
        'desFrente': 'Sotano 1',
        'desFase': 'Instalaciones sanitarias',
        'desActividad': 'Gestionar llegada de materiales',
        'desRestriccion': 'Material no llega segun cronograma de abastecimiento.',
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
        'codArea': '1',
        'desFrente': 'Lobby principal',
        'desFase': 'Acabados interiores y carpinteria',
        'desActividad': 'Coordinar entrega de planos revisados',
        'desRestriccion': 'Coordinar entrega de planos revisados con arquitectura.',
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
        'codArea': '3',
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
        'codArea': '1',
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
        'codArea': '4',
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

    batch.insert('meetings_meeting', {
      'codActReuReuniones': 501,
      'codProyecto': 101,
      'codActReu': 1,
      'codActReuCategoria': 1,
      'codActReuSubCategoria': 10,
      'desCategoria': 'Produccion',
      'desSubCategoria': 'Semanal',
      'desNombre': 'Reunion semanal de obra',
      'dayFechaReunion': '2026-03-12',
      'dayFechaCierre': '2026-03-12',
      'horHoraInicio': '08:00',
      'horHoraFin': '09:00',
      'codEstado': 'scheduled',
      'desEstado': 'Programada',
      'desLinkActaReunion': '',
      'updated_at': now,
    });
    batch.insert('meetings_meeting', {
      'codActReuReuniones': 502,
      'codProyecto': 101,
      'codActReu': 1,
      'codActReuCategoria': 2,
      'codActReuSubCategoria': 20,
      'desCategoria': 'Ingenieria',
      'desSubCategoria': 'Coordinacion',
      'desNombre': 'Coordinacion tecnica',
      'dayFechaReunion': '2026-03-15',
      'dayFechaCierre': '2026-03-15',
      'horHoraInicio': '16:00',
      'horHoraFin': '17:00',
      'codEstado': 'scheduled',
      'desEstado': 'Programada',
      'desLinkActaReunion': '',
      'updated_at': now,
    });

    for (final row in [
      {
        'codActReuAcuerdos': 601,
        'codActReuReuniones': 501,
        'codProyecto': 101,
        'desAcuerdo': 'Enviar planos actualizados',
        'dayFechaAcuerdo': '2026-03-11',
        'dayFechaAplazo': null,
        'dayFechaLevantamiento': null,
        'numAplazos': 0,
        'idUsuarioResponsable': 9,
        'desResponsable': 'Maria Torres',
        'codEstado': 'pending',
        'desEstado': 'Pendiente',
        'codGrupoAcuerdo': 1,
        'desGrupoAcuerdo': 'Pendiente',
        'desColorGrupoAcuerdo': '#F0A11E',
        'is_overdue': 0,
        'is_pending': 1,
        'is_completed': 0,
        'updated_at': now,
      },
      {
        'codActReuAcuerdos': 602,
        'codActReuReuniones': 501,
        'codProyecto': 101,
        'desAcuerdo': 'Cerrar observaciones de seguridad',
        'dayFechaAcuerdo': '2026-03-08',
        'dayFechaAplazo': null,
        'dayFechaLevantamiento': null,
        'numAplazos': 0,
        'idUsuarioResponsable': 8,
        'desResponsable': 'Juan Perez',
        'codEstado': 'overdue',
        'desEstado': 'Vencido',
        'codGrupoAcuerdo': 2,
        'desGrupoAcuerdo': 'Vencido',
        'desColorGrupoAcuerdo': '#D64545',
        'is_overdue': 1,
        'is_pending': 0,
        'is_completed': 0,
        'updated_at': now,
      },
    ]) {
      batch.insert('meetings_agreement', row);
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
    await _refreshProjectSummary(db, 101);
    await _refreshMeetingSummary(db, 101);
  }

  Future<void> _seedAreaCatalog(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM projects_area_member')) ?? 0;
    if (count == 0) {
      final batch = db.batch();
      for (final row in _areaSeedRows()) {
        batch.insert('projects_area_member', row, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    }

    await db.rawUpdate('''
      UPDATE anares_restriction
      SET codArea = (
        SELECT CAST(pm.codArea AS TEXT)
        FROM projects_member pm
        WHERE pm.user_id = anares_restriction.idUsuarioResponsable
        LIMIT 1
      )
      WHERE codArea IS NULL OR TRIM(codArea) = ''
    ''');
  }

  List<Map<String, Object?>> _areaSeedRows() {
    return const [
      {'codArea': 1, 'desArea': 'Supervision', 'cod_Empresa': 1},
      {'codArea': 2, 'desArea': 'Planeamiento', 'cod_Empresa': 1},
      {'codArea': 3, 'desArea': 'Produccion', 'cod_Empresa': 1},
      {'codArea': 4, 'desArea': 'Logistica', 'cod_Empresa': 1},
    ];
  }

  Future<void> refreshProjectSummary(DatabaseExecutor db, int projectId) async {
    await _refreshProjectSummary(db, projectId);
  }

  Future<void> refreshMeetingSummary(DatabaseExecutor db, int projectId) async {
    await _refreshMeetingSummary(db, projectId);
  }

  Future<void> _refreshProjectSummary(DatabaseExecutor db, int projectId) async {
    final row = (await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN is_overdue = 1 THEN 1 ELSE 0 END) AS overdue,
        SUM(CASE WHEN is_in_progress = 1 THEN 1 ELSE 0 END) AS in_progress,
        SUM(CASE WHEN is_pending = 1 THEN 1 ELSE 0 END) AS pending
      FROM anares_restriction
      WHERE codProyecto = ?
      ''',
      [projectId],
    ))
        .first;

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
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _refreshMeetingSummary(DatabaseExecutor db, int projectId) async {
    final counts = (await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN is_overdue = 1 THEN 1 ELSE 0 END) AS overdue,
        SUM(CASE WHEN is_pending = 1 THEN 1 ELSE 0 END) AS pending
      FROM meetings_agreement
      WHERE codProyecto = ?
      ''',
      [projectId],
    ))
        .first;
    final nextMeetingRows = await db.query(
      'meetings_meeting',
      columns: ['dayFechaReunion'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'dayFechaReunion ASC',
      limit: 1,
    );

    await db.insert('meetings_summary', {
      'codProyecto': projectId,
      'overdueAgreementsCount': (counts['overdue'] as int?) ?? 0,
      'pendingAgreementsCount': (counts['pending'] as int?) ?? 0,
      'nextMeetingDate': nextMeetingRows.isEmpty ? null : nextMeetingRows.first['dayFechaReunion'],
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
