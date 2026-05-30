import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SyncApiClient {
  static const Duration _pushRequestTimeout = Duration(seconds: 45);
  static const Duration _pullRequestTimeout = Duration(seconds: 60);

  SyncApiClient({String? baseUrl})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'DIREKTOR_API_BASE_URL',
            //defaultValue: 'https://desaapi.direktor.com.pe/api/mobile',
            defaultValue: 'https://api.direktor.com.pe/api/mobile',
          ),
      _pushInboxUrl = const String.fromEnvironment(
        'DIREKTOR_PUSH_INBOX_URL',
        defaultValue: 'http://31.220.20.226/api/mobile/sync/inbox',
      );

  final String _baseUrl;
  final String _pushInboxUrl;

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<SyncPushResult> pushInbox({
    required int userId,
    required List<Map<String, Object?>> items,
    String? authToken,
    Object? companyId,
    Object? deviceId,
  }) async {
    if (_pushInboxUrl.trim().isEmpty) {
      throw Exception(
        'No se configuro DIREKTOR_PUSH_INBOX_URL para enviar a sync_inbox.',
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse(_pushInboxUrl);
      final request = await client.postUrl(uri).timeout(_pushRequestTimeout);
      request.headers.contentType = ContentType.json;
      final normalizedToken = authToken?.trim();
      if (normalizedToken != null && normalizedToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $normalizedToken',
        );
      }
      final payload = <String, Object?>{
        'userId': userId,
        'deviceId': deviceId ?? 1,
        'source': 'direktor_appv2',
        'items': items,
      };
      if (companyId != null) {
        payload['companyId'] = companyId;
      }
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(_pushRequestTimeout);
      final body = await utf8
          .decodeStream(response)
          .timeout(_pushRequestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Sync inbox respondio ${response.statusCode}: $body');
      }

      return SyncPushResult(accepted: items.length, rawBody: body);
    } on TimeoutException {
      throw Exception(
        'Sync inbox excedio el tiempo maximo de ${_pushRequestTimeout.inSeconds}s.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<SyncPullResult> pullData({
    required int userId,
    required String scope,
    String? businessDate,
    String? since,
    String? authToken,
    String? companyId,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'No se configuro DIREKTOR_API_BASE_URL para descargar datos remotos.',
      );
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$_baseUrl/sync/pull');
      final request = await client.postUrl(uri).timeout(_pullRequestTimeout);
      request.headers.contentType = ContentType.json;
      final normalizedToken = authToken?.trim();
      final normalizedCompanyId = companyId?.trim();
      if (normalizedToken != null && normalizedToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $normalizedToken',
        );
      }
      final payload = <String, Object?>{
        'userId': userId,
        'source': 'direktor_appv2',
        'scope': scope,
      };
      if (normalizedCompanyId?.isNotEmpty ?? false) {
        payload['companyId'] = normalizedCompanyId;
      }
      if (businessDate != null) {
        payload['businessDate'] = businessDate;
      }
      if (since != null) {
        payload['since'] = since;
      }
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(_pullRequestTimeout);
      final body = await utf8
          .decodeStream(response)
          .timeout(_pullRequestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Sync pull respondio ${response.statusCode}: $body');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Sync pull respondio un JSON invalido.');
      }
      final normalizedPayload = _normalizePullPayload(decoded);

      return SyncPullResult(
        scope: scope,
        rawBody: body,
        payload: normalizedPayload,
      );
    } on TimeoutException {
      throw Exception(
        'Sync pull excedio el tiempo maximo de ${_pullRequestTimeout.inSeconds}s.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _normalizePullPayload(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return {...raw, ...data};
    }
    final payload = raw['payload'];
    if (payload is Map<String, dynamic>) {
      return {...raw, ...payload};
    }
    return raw;
  }
}

class SyncPushResult {
  const SyncPushResult({required this.accepted, required this.rawBody});

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
