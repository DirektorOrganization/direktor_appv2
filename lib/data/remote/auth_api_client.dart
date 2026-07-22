import 'dart:convert';
import 'dart:io';

import 'auth_login_contract_adapter.dart';

class AuthApiClient {
  AuthApiClient({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'DIREKTOR_API_BASE_URL',
              //defaultValue: 'https://desaapi.direktor.com.pe/api/mobile',
              defaultValue: 'https://api.direktor.com.pe/api/mobile',
            );

  final String _baseUrl;

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Future<AuthLoginResult> login({
    required String userOrEmail,
    required String password,
    required bool keepSignedIn,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'No se configuro DIREKTOR_API_BASE_URL para autenticacion remota.',
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.parse('$_baseUrl/auth/login');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        jsonEncode({
          'userOrEmail': userOrEmail,
          'password': password,
          'keepSignedIn': keepSignedIn,
          'source': 'direktor_appv2',
        }),
      ),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    client.close(force: true);

    Map<String, dynamic>? decodedBody;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        decodedBody = decoded;
      } else if (decoded is Map) {
        decodedBody = decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      decodedBody = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(decodedBody, body, response.statusCode),
      );
    }

    if (decodedBody == null) {
      throw Exception('Auth login respondio un JSON invalido.');
    }

    final adaptation = adaptAuthLoginPayload(decodedBody);
    final decoded = adaptation.payload;

    final success = decoded['success'];
    if (success is bool && !success) {
      throw Exception(
        decoded['mensaje']?.toString() ??
            decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'Credenciales invalidas',
      );
    }

    final user = decoded['user'];
    if (user is! Map) {
      throw Exception('Auth login no devolvio user.');
    }

    final userMap = user.map((key, value) => MapEntry('$key', value));
    final companyId =
        userMap['companyId']?.toString().trim() ??
        userMap['nombreempresa']?.toString().trim();
    if (companyId == null || companyId.isEmpty) {
      throw Exception('Auth login no devolvio companyId/nombreempresa.');
    }
    final projects = decoded['projects'];
    final projectList = projects is List
        ? projects
              .whereType<Map>()
              .map((item) => item.map((key, value) => MapEntry('$key', value)))
              .where((item) => item['perfilUsuario'] is Map)
              .toList()
        : const <Map<String, dynamic>>[];
    final activeSubscription = decoded['suscripcionActiva'];
    final activeSubscriptionMap = activeSubscription is Map
        ? activeSubscription.map((key, value) => MapEntry('$key', value))
        : null;

    return AuthLoginResult(
      token: decoded['token']?.toString() ?? '',
      refreshToken: decoded['refreshToken']?.toString() ?? '',
      user: userMap,
      projects: projectList,
      activeSubscription: activeSubscriptionMap,
      usedTemporaryAuthorizationMock: adaptation.usedTemporaryMock,
    );
  }
}

String _extractErrorMessage(
  Map<String, dynamic>? decodedBody,
  String rawBody,
  int statusCode,
) {
  final bodyMessage = decodedBody?['mensaje']?.toString().trim();
  if (bodyMessage != null && bodyMessage.isNotEmpty) {
    return bodyMessage;
  }

  final message = decodedBody?['message']?.toString().trim();
  if (message != null && message.isNotEmpty) {
    return message;
  }

  final error = decodedBody?['error']?.toString().trim();
  if (error != null && error.isNotEmpty) {
    return error;
  }

  final body = rawBody.trim();
  if (body.isNotEmpty) {
    return body;
  }

  return 'Auth login respondio $statusCode.';
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.projects,
    required this.activeSubscription,
    required this.usedTemporaryAuthorizationMock,
  });

  final String token;
  final String refreshToken;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> projects;
  final Map<String, dynamic>? activeSubscription;
  final bool usedTemporaryAuthorizationMock;
}




