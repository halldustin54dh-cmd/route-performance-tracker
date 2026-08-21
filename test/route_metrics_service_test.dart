import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/checkpoint.dart';
import 'package:route_performance_tracker/models/delivery_route.dart';
import 'package:route_performance_tracker/models/route_event.dart';
import 'package:route_performance_tracker/services/route_metrics_service.dart';

void main() {
  const service = RouteMetricsService();

  test('planned route has no pace before first stop', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 184,
      startingLocations: 226,
      startingPackages: 312,
    );

    expect(service.rawPace(route), isNull);
    expect(service.forecast(route), isNull);
  });

  test('forecast begins after two checkpoints', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 184,
      startingLocations: 0,
      startingPackages: 0,
      firstStopTime: DateTime(2026, 8, 20, 10, 47),
    );

    route.checkpoints.add(
      Checkpoint(stopNumber: 1, timestamp: DateTime(2026, 8, 20, 10, 47)),
    );
    expect(service.forecast(route), isNull);

    route.checkpoints.add(
      Checkpoint(stopNumber: 33, timestamp: DateTime(2026, 8, 20, 11, 47)),
    );

    final forecast = service.forecast(route);
    expect(forecast, isNotNull);
    expect(forecast!.forecastPace, greaterThan(0));
    expect(forecast.confidence, 'Low');
  });

  test('adjusted pace removes in-window documented delay', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 184,
      startingLocations: 0,
      startingPackages: 0,
      firstStopTime: DateTime(2026, 8, 20, 10, 47),
    );
    route.checkpoints.addAll([
      Checkpoint(stopNumber: 1, timestamp: DateTime(2026, 8, 20, 10, 47)),
      Checkpoint(stopNumber: 47, timestamp: DateTime(2026, 8, 20, 13, 4)),
    ]);
    route.events.add(
      RouteEvent(
        type: RouteEventType.wrongAddress,
        timestamp: DateTime(2026, 8, 20, 12, 54),
        delayMinutes: 10,
      ),
    );

    expect(service.adjustedPace(route), greaterThan(service.rawPace(route)!));
  });
}
