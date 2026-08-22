import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_vision_analysis.dart';
import 'account_service.dart';

class RouteVisionService {
  const RouteVisionService();

  static const _baseUrl = String.fromEnvironment(
    'ROUTE_VISION_BASE_URL',
    defaultValue: 'https://route-performance-tracker-vision.vercel.app',
  );
  static const _clientToken = String.fromEnvironment('ROUTE_VISION_CLIENT_TOKEN');
  static const maxImagesPerAnalysis = 3;
  static const freeMonthlyAnalyses = 3;
  static const _targetBytesPerImage = 700 * 1024;

  bool get isConfigured => _clientToken.isNotEmpty;

  Future<RouteVisionAnalysis> analyze({required List<String> imagePaths, String ocrText = ''}) async {
    if (!isConfigured) throw StateError('Secure vision is unavailable in this build.');
    if (imagePaths.isEmpty) throw ArgumentError('At least one image is required.');

    final accounts = AccountService.instance;
    if (!accounts.isInitialized || accounts.currentUser == null) {
      throw StateError('Sign in to use AI screenshot analysis. Free accounts include 3 analyses each month.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Your account session expired. Sign in again to use AI analysis.');
    }

    final images = <Map<String, String>>[];
    for (final path in imagePaths.take(maxImagesPerAnalysis)) {
      final bytes = await _visionSizedJpeg(path);
      images.add({'mimeType': 'image/jpeg', 'base64': base64Encode(bytes)});
    }

    final uri = Uri.parse('${_baseUrl.replaceAll(RegExp(r'/$'), '')}/api/route-vision');
    final response = await http.post(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        'X-RPT-Client-Token': _clientToken,
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({'images': images, 'ocrText': ocrText}),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 402) {
      throw StateError('You have used your 3 free AI analyses this month. Upgrade to Pro for expanded AI analysis.');
    }
    if (response.statusCode == 401) throw StateError('Sign in again to use AI screenshot analysis.');
    if (response.statusCode == 503) throw StateError('Secure vision is temporarily unavailable. You can still enter the route manually.');
    if (response.statusCode == 429) throw StateError('Secure vision is temporarily rate limited. Try again shortly.');
    if (response.statusCode != 200) throw StateError('Secure vision could not analyze these screenshots.');

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
    if (encoded.length > _targetBytesPerImage) throw StateError('One screenshot is still too large for secure vision analysis.');
    return encoded;
  }

  img.Image _resizeLongestSide(img.Image source, int maxSide) {
    if (source.width <= maxSide && source.height <= maxSide) return source;
    if (source.width >= source.height) return img.copyResize(source, width: maxSide, interpolation: img.Interpolation.linear);
    return img.copyResize(source, height: maxSide, interpolation: img.Interpolation.linear);
  }
}
