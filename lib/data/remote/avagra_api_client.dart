import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class AvagraApiClient {
  AvagraApiClient({String? baseUrl})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'DIREKTOR_API_BASE_URL',
            defaultValue: 'http://192.168.18.5:5001/api/mobile',
          );

  final String _baseUrl;

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Uri _buildBaseUrlUri(String suffixPath) {
    final parsed = Uri.parse(_baseUrl.trim());
    final basePath = parsed.path.endsWith('/')
        ? parsed.path.substring(0, parsed.path.length - 1)
        : parsed.path;
    return parsed.replace(path: '$basePath$suffixPath');
  }

  Uri _phase3UploadPlanUri() {
    return _buildBaseUrlUri('/avagra/fase_tres/upload-plano');
  }

  Uri _phase3DownloadPlanUri() {
    return _buildBaseUrlUri('/avagra/fasetres/pisos/descargar-plano');
  }

  void _setBearer(HttpClientRequest request, String? authToken) {
    final normalizedToken = authToken?.trim();
    if (normalizedToken != null && normalizedToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $normalizedToken',
      );
    }
  }

  Future<Phase3PlanUploadResult> uploadPhase3FloorPlan({
    required int floorId,
    required String filePath,
    String? authToken,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('No se encontro el archivo a subir: $filePath');
    }

    final uri = _phase3UploadPlanUri();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final request = await client.postUrl(uri);
    _setBearer(request, authToken);

    final boundary =
        '----direktorBoundary${DateTime.now().microsecondsSinceEpoch}';
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    final filename = file.uri.pathSegments.isEmpty
        ? 'plano'
        : file.uri.pathSegments.last;
    final ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase()
        : 'jpg';
    final mimeByExt = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'webp': 'image/webp',
    };
    final mimeType = mimeByExt[ext] ?? 'application/octet-stream';
    final bytes = await file.readAsBytes();

    void writeTextField(String name, String value) {
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="$name"\r\n\r\n',
      );
      request.write('$value\r\n');
    }

    writeTextField('codPiso', '$floorId');
    request.write('--$boundary\r\n');
    request.write(
      'Content-Disposition: form-data; name="plano"; filename="$filename"\r\n',
    );
    request.write('Content-Type: $mimeType\r\n\r\n');
    request.add(bytes);
    request.write('\r\n');
    request.write('--$boundary--\r\n');

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    client.close(force: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload plano respondio ${response.statusCode}: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Upload plano devolvio un JSON invalido.');
    }
    final piso = decoded['piso'];
    final pisoMap = piso is Map
        ? piso.map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};
    return Phase3PlanUploadResult(
      success: decoded['error'] != true,
      message: decoded['message']?.toString(),
      planLink: pisoMap['desLinkPlano']?.toString(),
      planName: pisoMap['desNombrePlano']?.toString(),
      rawBody: body,
    );
  }

  Future<Phase3PlanDownloadResult> downloadPhase3FloorPlan({
    required int floorId,
    String? authToken,
  }) async {
    final uri = _phase3DownloadPlanUri().replace(
      queryParameters: <String, String>{'codPiso': '$floorId'},
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    var responseBytes = Uint8List(0);
    HttpHeaders? headers;
    var statusCode = 0;

    Future<void> consume(HttpClientResponse response) async {
      statusCode = response.statusCode;
      headers = response.headers;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      responseBytes = builder.takeBytes();
    }

    final getRequest = await client.getUrl(uri);
    _setBearer(getRequest, authToken);
    await consume(await getRequest.close());

    if (statusCode == 405 || statusCode == 415 || statusCode == 422) {
      final fallbackUri = _phase3DownloadPlanUri();
      final postRequest = await client.postUrl(fallbackUri);
      _setBearer(postRequest, authToken);
      postRequest.headers.contentType = ContentType.json;
      postRequest.add(utf8.encode(jsonEncode({'codPiso': floorId})));
      await consume(await postRequest.close());
    }

    client.close(force: true);
    if (statusCode < 200 || statusCode >= 300) {
      final bodyText = utf8.decode(responseBytes, allowMalformed: true);
      throw Exception('Descarga de plano respondio $statusCode: $bodyText');
    }

    final contentType = headers
        ?.value(HttpHeaders.contentTypeHeader)
        ?.toLowerCase();
    final contentDisposition = headers?.value('content-disposition');
    String? fileName;
    if (contentDisposition != null) {
      final filenameMatch = RegExp(
        r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
        caseSensitive: false,
      ).firstMatch(contentDisposition);
      if (filenameMatch != null) {
        fileName = Uri.decodeComponent(filenameMatch.group(1) ?? '').trim();
      }
    }
    return Phase3PlanDownloadResult(
      bytes: responseBytes,
      contentType: contentType,
      fileName: fileName,
    );
  }
}

class Phase3PlanUploadResult {
  const Phase3PlanUploadResult({
    required this.success,
    required this.message,
    required this.planLink,
    required this.planName,
    required this.rawBody,
  });

  final bool success;
  final String? message;
  final String? planLink;
  final String? planName;
  final String rawBody;
}

class Phase3PlanDownloadResult {
  const Phase3PlanDownloadResult({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String? contentType;
  final String? fileName;
}
