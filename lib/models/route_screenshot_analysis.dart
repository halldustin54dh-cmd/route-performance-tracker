enum RouteScreenshotKind {
  pickSheet('Pick sheet'),
  itinerary('Itinerary'),
  routeMap('Route map'),
  unknown('Unclassified');

  const RouteScreenshotKind(this.label);
  final String label;
}

class RouteScreenshotAnalysis {
  const RouteScreenshotAnalysis({
    required this.filePath,
    required this.kind,
    required this.rawText,
    this.stops,
    this.locations,
    this.packages,
    this.multiLocationStops,
    this.routeCode,
    this.confidence = 0,
    this.notes = const [],
  });

  final String filePath;
  final RouteScreenshotKind kind;
  final String rawText;
  final int? stops;
  final int? locations;
  final int? packages;
  final int? multiLocationStops;
  final String? routeCode;
  final double confidence;
  final List<String> notes;
}

class RouteScreenshotBatchAnalysis {
  const RouteScreenshotBatchAnalysis({required this.items});

  final List<RouteScreenshotAnalysis> items;

  int? get stops => _bestInt((item) => item.stops);
  int? get locations => _bestInt((item) => item.locations);
  int? get packages => _bestInt((item) => item.packages);
  int? get multiLocationStops => _bestInt((item) => item.multiLocationStops);

  int? _bestInt(int? Function(RouteScreenshotAnalysis) read) {
    final values = <int>[];
    for (final item in items) {
      final value = read(item);
      if (value != null && value > 0) values.add(value);
    }
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  bool get hasUsefulRouteData => stops != null || locations != null || packages != null || multiLocationStops != null;
}
