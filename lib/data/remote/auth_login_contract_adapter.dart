class AuthLoginPayloadAdaptationResult {
  const AuthLoginPayloadAdaptationResult({
    required this.payload,
    required this.usedTemporaryMock,
  });

  final Map<String, dynamic> payload;
  final bool usedTemporaryMock;
}

AuthLoginPayloadAdaptationResult adaptAuthLoginPayload(
  Map<String, dynamic> payload,
) {
  final normalized = Map<String, dynamic>.from(payload);
  final user = _normalizeMap(normalized['user']) ?? <String, dynamic>{};
  final companyCode = _asInt(user['cod_Empresa']) ?? 0;
  final userId = _asInt(user['id']) ?? 0;

  user['codEstadoUsuarioxSuscripcion'] =
      _asInt(user['codEstadoUsuarioxSuscripcion']) ?? 1;
  user['flgSuperAdmin'] = _asInt(user['flgSuperAdmin']) ?? 0;
  normalized['user'] = user;

  var usedTemporaryMock = false;
  var activeSubscription = _normalizeMap(normalized['suscripcionActiva']);
  if (activeSubscription == null) {
    activeSubscription = _buildTemporaryActiveSubscription(
      companyCode: companyCode,
      userId: userId,
    );
    normalized['suscripcionActiva'] = activeSubscription;
    usedTemporaryMock = true;
  }

  final rawProjects = normalized['projects'];
  final projectList = rawProjects is List
      ? rawProjects
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', value)))
            .toList()
      : const <Map<String, dynamic>>[];

  final normalizedProjects = <Map<String, dynamic>>[];
  for (final project in projectList) {
    final normalizedProject = Map<String, dynamic>.from(project);
    var profile = _normalizeMap(normalizedProject['perfilUsuario']);
    if (profile == null) {
      profile = _buildTemporaryProjectProfile(activeSubscription);
      normalizedProject['perfilUsuario'] = profile;
      usedTemporaryMock = true;
    }

    if (profile == null) {
      continue;
    }

    normalizedProjects.add(normalizedProject);
  }
  normalized['projects'] = normalizedProjects;

  return AuthLoginPayloadAdaptationResult(
    payload: normalized,
    usedTemporaryMock: usedTemporaryMock,
  );
}

Map<String, dynamic>? _normalizeMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, value) => MapEntry('$key', value));
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _buildTemporaryActiveSubscription({
  required int companyCode,
  required int userId,
}) {
  return <String, dynamic>{
    'cod_Empresa': companyCode,
    'codSuscripcion': 1,
    'dayFechaInicio': '2026-06-25',
    'dayFechaFin': '2027-06-25',
    'dayFechaCancelada': null,
    'codEstado': 1,
    'codVendedor': null,
    'numProyectosGratisUsados': 1,
    'numProyectosUsados': 29,
    'numLimiteProyectos': 50,
    'numAlertasWspUsados': 0,
    'numAlertasWspGratisUsados': 0,
    'desCorreoContacto': null,
    'flgAutoAprobarUsuarios': 1,
    'codPerfilPredeterminado': null,
    'codMoneda': 1,
    'dayFechaCreacion': '2026-06-08 08:37:43',
    'dayFechaModificacion': '2026-06-25 18:21:32',
    'codUsuarioCreacion': userId > 0 ? userId : null,
    'codUsuarioModificacion': userId > 0 ? userId : null,
    'modulos': <Map<String, dynamic>>[
      {
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codModulo': 1,
        'desModulo': 'Proyecto restricciones',
        'desModuloAbrev': 'ANARES',
        'codEstado': 1,
      },
      {
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codModulo': 2,
        'desModulo': 'Acta de Reuniones',
        'desModuloAbrev': 'ACTAREU',
        'codEstado': 1,
      },
      {
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codModulo': 3,
        'desModulo': 'Analisis de Proyectos',
        'desModuloAbrev': 'ANAPROY',
        'codEstado': 1,
      },
      {
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codModulo': 5,
        'desModulo': 'Control de Hitos',
        'desModuloAbrev': 'CONHIT',
        'codEstado': 0,
      },
      {
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codModulo': 6,
        'desModulo': 'Avance de Grafico',
        'desModuloAbrev': 'AVAGRA',
        'codEstado': 0,
      },
    ],
    'servicios': <Map<String, dynamic>>[
      {
        'codServicioSuscripcion': 2,
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codEstado': 1,
        'desServicio': 'Alertas por correo',
        'desAbrev': 'SERV_ALERTAS_CORREO',
        'desDescripcion':
            'Servicio de notificaciones por correo en los modulos',
        'desIcono': null,
        'desColor': null,
      },
      {
        'codServicioSuscripcion': 3,
        'cod_Empresa': companyCode,
        'codSuscripcion': 1,
        'codEstado': 0,
        'desServicio': 'Alertas por WhatsApp',
        'desAbrev': 'SERV_ALERTAS_WSP',
        'desDescripcion':
            'Servicio de notificaciones por WhatsApp en los modulos',
        'desIcono': null,
        'desColor': null,
      },
    ],
  };
}

Map<String, dynamic>? _buildTemporaryProjectProfile(
  Map<String, dynamic> activeSubscription,
) {
  final rawModules = activeSubscription['modulos'];
  if (rawModules is! List) {
    return null;
  }

  final permissions = rawModules
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry('$key', value)))
      .where((module) => _asInt(module['codEstado']) == 1)
      .map(
        (module) => <String, dynamic>{
          'codPerfilEmpresa': 1,
          'codPermisoUsuario': 1,
          'codModulo': _asInt(module['codModulo']) ?? 0,
          'desPermisoUsuario': 'Admin',
          'desDescripcionPermiso': 'Permiso de administracion total',
          'desModulo': module['desModulo'],
          'desModuloAbrev': module['desModuloAbrev'],
        },
      )
      .where((permission) => (permission['codModulo'] as int) > 0)
      .toList();

  if (permissions.isEmpty) {
    return null;
  }

  return <String, dynamic>{
    'codPerfilEmpresa': 1,
    'desPerfilEmpresa': 'Administrador',
    'desDescripcionPerfilEmpresa': null,
    'permisosxmodulo': permissions,
  };
}
