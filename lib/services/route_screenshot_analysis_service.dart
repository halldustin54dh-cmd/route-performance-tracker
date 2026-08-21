import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/route_screenshot_analysis.dart';

class RouteScreenshotAnalysisService {
  const RouteScreenshotAnalysisService();

  Future<RouteScreenshotBatchAnalysis> analyze(List<String> paths) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final items = <RouteScreenshotAnalysis>[];
    try {
      for (final path in paths) {
        final image = InputImage.fromFilePath(path);
        final recognized = await recognizer.processImage(image);
        items.add(analyzeText(path: path, text: recognized.text));
      }
    } finally {
      await recognizer.close();
    }
    return RouteScreenshotBatchAnalysis(items: items);
  }

  RouteScreenshotAnalysis analyzeText({required String path, required String text}) {
    final normalized = text.replaceAll('\r', '\n');
    final lower = normalized.toLowerCase();
    final kind = _classify(lower);
    final stops = _extractCount(normalized, const ['stops?']);
    final locations = _extractCount(normalized, const ['locations?', 'delivery[ ]+locations?']);
    final packages = _extractCount(normalized, const ['packages?', 'pkgs?']);
    final multi = _extractCount(normalized, const ['multi[- ]?location[ ]+stops?', 'grouped[ ]+stops?', 'multi[- ]?stops?']);
    final routeCode = _extractRouteCode(normalized);
    final notes = <String>[];

    if (kind == RouteScreenshotKind.routeMap) {
      notes.add('Map detected from visible labels. Full geographic interpretation requires the vision-analysis backend.');
    }
    if (normalized.trim().isEmpty) {
      notes.add('No readable text detected. Keep this screenshot as route documentation and review it manually.');
    }

    final foundFields = [stops, locations, packages, multi].where((value) => value != null).length;
    final double confidence = switch (kind) {
      RouteScreenshotKind.pickSheet => (0.62 + foundFields * 0.08).clamp(0.0, 0.94).toDouble(),
      RouteScreenshotKind.itinerary => (0.58 + foundFields * 0.07).clamp(0.0, 0.90).toDouble(),
      RouteScreenshotKind.routeMap => 0.62,
      RouteScreenshotKind.unknown => foundFields > 1 ? 0.55 : 0.25,
    };

    return RouteScreenshotAnalysis(
      filePath: path,
      kind: kind,
      rawText: normalized,
      stops: stops,
      locations: locations,
      packages: packages,
      multiLocationStops: multi,
      routeCode: routeCode,
      confidence: confidence,
      notes: notes,
    );
  }

  RouteScreenshotKind _classify(String lower) {
    final pickScore = _score(lower, const [
      'pick sheet', 'staging', 'bags', 'overflow', 'packages', 'route code', 'loadout',
    ]);
    final itineraryScore = _score(lower, const [
      'itinerary', 'stop 1', 'stop 2', 'delivery', 'locations', 'continue delivering',
    ]);
    final mapScore = _score(lower, const [
      'map', 'route overview', 'recenter', 'navigation', 'current location',
    ]);

    if (pickScore >= 2 && pickScore >= itineraryScore) return RouteScreenshotKind.pickSheet;
    if (itineraryScore >= 2 && itineraryScore > pickScore) return RouteScreenshotKind.itinerary;
    if (mapScore >= 1 && mapScore >= pickScore && mapScore >= itineraryScore) return RouteScreenshotKind.routeMap;
    return RouteScreenshotKind.unknown;
  }

  int _score(String text, List<String> needles) => needles.where(text.contains).length;

  int? _extractCount(String text, List<String> labels) {
    for (final line in text.split('\n')) {
      for (final label in labels) {
        final after = RegExp(
          '\\b(?:$label)\\b[ \\t]*[:#-]?[ \\t]*(\\d{1,4})',
          caseSensitive: false,
        ).firstMatch(line);
        if (after != null) return int.tryParse(after.group(1)!);

        final before = RegExp(
          '\\b(\\d{1,4})[ \\t]*(?:$label)\\b',
          caseSensitive: false,
        ).firstMatch(line);
        if (before != null) return int.tryParse(before.group(1)!);
      }
    }
    return null;
  }

  String? _extractRouteCode(String text) {
    final match = RegExp(r'(?:route|route code)\s*[:#-]?\s*([A-Z0-9_-]{3,20})', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.toUpperCase();
  }
}
