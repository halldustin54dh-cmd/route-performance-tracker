import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/route_vision_analysis.dart';

class RouteVisionService {
  const RouteVisionService();

  static const _baseUrl = String.fromEnvironment('ROUTE_VISION_BASE_URL');
  static const _clientToken = String.fromEnvironment('ROUTE_VISION_CLIENT_TOKEN');
  static const _maxImages = 3;
  static const _targetBytesPerImage = 700 * 1024;

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
    for (final path in imagePaths.take(_maxImages)) {
      final bytes = await _visionSizedJpeg(path);
      images.add({
        'mimeType': 'image/jpeg',
        'base64': base64Encode(bytes),
      });
    }

    final uri = Uri.parse('${_baseUrl.replaceAll(RegExp(r'/$'), '')}/api/route-vision');
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

    if (response.statusCode == 503) {
      throw StateError('Secure vision backend is online but has not been configured yet.');
    }
    if (response.statusCode == 401) {
      throw StateError('Secure vision backend rejected this app build.');
    }
    if (response.statusCode == 429) {
      throw StateError('Secure vision analysis is temporarily rate limited.');
    }
    if (response.statusCode != 200) {
      throw StateError('Vision backend returned ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid vision response.');
    return RouteVisionAnalysis.fromJson(decoded);
  }

  Future<List<int>> _visionSizedJpeg(String path) async {
    final source = await File(path).readAsBytes();
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      if (source.length <= _targetBytesPerImage) return source;
      throw StateError('Could not prepare one screenshot for secure vision analysis.');
    }

    var working = _resizeLongestSide(decoded, 1400);
    var encoded = img.encodeJpg(working, quality: 72);
    if (encoded.length <= _targetBytesPerImage) return encoded;

    working = _resizeLongestSide(decoded, 1100);
    encoded = img.encodeJpg(working, quality: 64);
    if (encoded.length <= _targetBytesPerImage) return encoded;

    working = _resizeLongestSide(decoded, 900);
    encoded = img.encodeJpg(working, quality: 56);
    if (encoded.length > _targetBytesPerImage) {
      throw StateError('One screenshot is still too large for secure vision analysis.');
    }
    return encoded;
  }

  img.Image _resizeLongestSide(img.Image source, int maxSide) {
    if (source.width <= maxSide && source.height <= maxSide) return source;
    if (source.width >= source.height) {
      return img.copyResize(source, width: maxSide, interpolation: img.Interpolation.linear);
    }
    return img.copyResize(source, height: maxSide, interpolation: img.Interpolation.linear);
  }
}
