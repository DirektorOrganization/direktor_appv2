import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SyncApiClient {
  SyncApiClient({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'DIREKTOR_API_BASE_URL',
              defaultValue: 'https://virtserver.swaggerhub.com/direktorsac/direktor-mobile-sync-api/1.0.0',
            );

  final String _baseUrl;

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<SyncPushResult> pushInbox({
    required int userId,
    required List<Map<String, Object?>> items,
  }) async {
    if (!isConfigured) {
      throw Exception('No se configuro DIREKTOR_API_BASE_URL para enviar a sync_inbox.');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.parse('$_baseUrl/sync/inbox');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        jsonEncode({
          'userId': userId,
          'source': 'direktor_appv2',
          'items': items,
        }),
      ),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    client.close(force: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sync inbox respondio ${response.statusCode}: $body');
    }

    return SyncPushResult(
      accepted: items.length,
      rawBody: body,
    );
  }

  Future<SyncPullResult> pullData({
    required int userId,
    required String scope,
    String? businessDate,
    String? since,
  }) async {
    if (!isConfigured) {
      throw Exception('No se configuro DIREKTOR_API_BASE_URL para descargar datos remotos.');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.parse('$_baseUrl/sync/pull');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        jsonEncode({
          'userId': userId,
          'source': 'direktor_appv2',
          'scope': scope,
          if (businessDate != null) 'businessDate': businessDate,
          if (since != null) 'since': since,
        }),
      ),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    client.close(force: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sync pull respondio ${response.statusCode}: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Sync pull respondio un JSON invalido.');
    }

    return SyncPullResult(
      scope: scope,
      rawBody: body,
      payload: decoded,
    );
  }
}

class SyncPushResult {
  const SyncPushResult({
    required this.accepted,
    required this.rawBody,
  });

  final int accepted;
  final String rawBody;
}

class SyncPullResult {
  const SyncPullResult({
    required this.scope,
    required this.rawBody,
    required this.payload,
  });

  final String scope;
  final String rawBody;
  final Map<String, dynamic> payload;
}
