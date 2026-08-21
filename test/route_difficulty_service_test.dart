import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/delivery_route.dart';
import 'package:route_performance_tracker/services/route_difficulty_service.dart';

void main() {
  const service = RouteDifficultyService();

  test('returns null when route does not contain enough context', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 180,
      startingLocations: 220,
      startingPackages: 300,
    );
    expect(service.calculate(route), isNull);
  });

  test('scores a contextualized route', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 180,
      startingLocations: 225,
      startingPackages: 310,
      apartmentStops: 30,
      ruralStops: 20,
      routeSpread: 3,
    );
    final result = service.calculate(route);
    expect(result, isNotNull);
    expect(result!.score, greaterThan(0));
    expect(result.score, lessThanOrEqualTo(100));
  });
}
