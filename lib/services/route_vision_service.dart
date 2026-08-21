import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/route_vision_analysis.dart';

class RouteVisionService {
  const RouteVisionService();

  static const _baseUrl = String.fromEnvironment('ROUTE_VISION_BASE_URL');
  static const _clientToken = String.fromEnvironment('ROUTE_VISION_CLIENT_TOKEN');

  bool get isConfigured => _baseUrl.isNotEmpty && _clientToken.isNotEmpty;

  Future<RouteVisionAnalysis> analyze({
    required List<String> imagePaths,
    String ocrText = '',
  }) async {
    if (!isConfigured) {
      throw StateError('Secure vision backend is not configured in this build.');
    }
    if (imagePaths.isEmpty) throw ArgumentError('At least one image is required.');

    final images = <Map<String, String>>[];
    for (final path in imagePaths.take(6)) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 6 * 1024 * 1024) {
        throw StateError('One screenshot is too large for vision analysis.');
      }
      images.add({
        'mimeType': _mimeType(path),
        'base64': base64Encode(bytes),
      });
    }

    final uri = Uri.parse('${_baseUrl.replaceAll(RegExp(r'/$'), '')}/v1/route-vision');
    final response = await http
        .post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $_clientToken',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode({'images': images, 'ocrText': ocrText}),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw StateError('Vision backend returned ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid vision response.');
    return RouteVisionAnalysis.fromJson(decoded);
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
