import 'dart:convert';
import 'dart:io';

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
      throw Exception('No se configuro DIREKTOR_API_BASE_URL para autenticacion remota.');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Auth login respondio ${response.statusCode}: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Auth login respondio un JSON invalido.');
    }

    final success = decoded['success'];
    if (success is bool && !success) {
      throw Exception(decoded['message']?.toString() ?? 'Credenciales invalidas');
    }

    final user = decoded['user'];
    if (user is! Map) {
      throw Exception('Auth login no devolvio user.');
    }

    final userMap = user.map((key, value) => MapEntry('$key', value));
    final companyId = userMap['companyId']?.toString().trim();
    if (companyId == null || companyId.isEmpty) {
      throw Exception('Auth login no devolvio companyId.');
    }
    final projects = decoded['projects'];
    final projectList = projects is List ? projects.whereType<Map>().map((item) => item.map((key, value) => MapEntry('$key', value))).toList() : const <Map<String, dynamic>>[];

    return AuthLoginResult(
      token: decoded['token']?.toString() ?? '',
      refreshToken: decoded['refreshToken']?.toString() ?? '',
      user: userMap,
      projects: projectList,
    );
  }
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.projects,
  });

  final String token;
  final String refreshToken;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> projects;
}




