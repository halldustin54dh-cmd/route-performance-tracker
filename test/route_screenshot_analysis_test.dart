import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/route_screenshot_analysis.dart';
import 'package:route_performance_tracker/services/route_screenshot_analysis_service.dart';

void main() {
  const service = RouteScreenshotAnalysisService();

  test('extracts pick sheet counts and classifies it', () {
    final result = service.analyzeText(
      path: 'pick.png',
      text: 'Pick Sheet\nStaging A-12\n190 Stops\n245 Locations\n331 Packages\n18 Bags\n24 Overflow\nRoute: CX123',
    );

    expect(result.kind, RouteScreenshotKind.pickSheet);
    expect(result.stops, 190);
    expect(result.locations, 245);
    expect(result.packages, 331);
    expect(result.routeCode, 'CX123');
  });

  test('extracts counts when labels precede values', () {
    final result = service.analyzeText(
      path: 'itinerary.png',
      text: 'Itinerary\nStops: 184\nLocations: 231\nPackages: 309\nContinue Delivering',
    );

    expect(result.kind, RouteScreenshotKind.itinerary);
    expect(result.stops, 184);
    expect(result.locations, 231);
    expect(result.packages, 309);
  });

  test('batch keeps the largest positive detected totals', () {
    final a = service.analyzeText(path: 'a.png', text: 'Pick Sheet\n180 Stops\n300 Packages\nStaging\nBags');
    final b = service.analyzeText(path: 'b.png', text: 'Itinerary\nStops: 184\nLocations: 230\nDelivery');
    final batch = RouteScreenshotBatchAnalysis(items: [a, b]);

    expect(batch.stops, 184);
    expect(batch.locations, 230);
    expect(batch.packages, 300);
  });
}
