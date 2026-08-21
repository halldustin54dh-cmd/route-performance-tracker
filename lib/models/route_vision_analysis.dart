class RouteVisionAnalysis {
  const RouteVisionAnalysis({
    required this.routeSpread,
    required this.rurality,
    required this.clustering,
    required this.backtrackingRisk,
    required this.accessComplexity,
    required this.estimatedAverageDriveMinutes,
    required this.likelyRouteType,
    required this.summary,
    required this.confidence,
    required this.signals,
  });

  final int routeSpread;
  final int rurality;
  final int clustering;
  final int backtrackingRisk;
  final int accessComplexity;
  final double? estimatedAverageDriveMinutes;
  final String likelyRouteType;
  final String summary;
  final double confidence;
  final List<String> signals;

  factory RouteVisionAnalysis.fromJson(Map<String, dynamic> json) => RouteVisionAnalysis(
        routeSpread: (json['routeSpread'] as num?)?.round() ?? 0,
        rurality: (json['rurality'] as num?)?.round() ?? 0,
        clustering: (json['clustering'] as num?)?.round() ?? 0,
        backtrackingRisk: (json['backtrackingRisk'] as num?)?.round() ?? 0,
        accessComplexity: (json['accessComplexity'] as num?)?.round() ?? 0,
        estimatedAverageDriveMinutes: (json['estimatedAverageDriveMinutes'] as num?)?.toDouble(),
        likelyRouteType: json['likelyRouteType'] as String? ?? 'Mixed',
        summary: json['summary'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        signals: (json['signals'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      );
}
