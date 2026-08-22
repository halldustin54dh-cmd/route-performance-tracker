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

    route.checkpoints.add(Checkpoint(stopNumber: 1, timestamp: DateTime(2026, 8, 20, 10, 47)));
    expect(service.forecast(route), isNull);

    route.checkpoints.add(Checkpoint(stopNumber: 33, timestamp: DateTime(2026, 8, 20, 11, 47)));

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
    route.events.add(RouteEvent(
      type: RouteEventType.wrongAddress,
      timestamp: DateTime(2026, 8, 20, 12, 54),
      delayMinutes: 10,
    ));

    expect(service.adjustedPace(route), greaterThan(service.rawPace(route)!));
  });

  test('dense real-route checkpoints produce a sane late-day forecast', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 193,
      startingLocations: 0,
      startingPackages: 0,
      firstStopTime: DateTime(2026, 8, 20, 10, 58),
    );
    route.checkpoints.addAll([
      Checkpoint(stopNumber: 1, timestamp: DateTime(2026, 8, 20, 10, 58)),
      Checkpoint(stopNumber: 36, timestamp: DateTime(2026, 8, 20, 11, 33)),
      Checkpoint(stopNumber: 49, timestamp: DateTime(2026, 8, 20, 12, 33)),
      Checkpoint(stopNumber: 77, timestamp: DateTime(2026, 8, 20, 13, 33)),
      Checkpoint(stopNumber: 95, timestamp: DateTime(2026, 8, 20, 14, 38)),
      Checkpoint(stopNumber: 147, timestamp: DateTime(2026, 8, 20, 16, 42)),
      Checkpoint(stopNumber: 168, timestamp: DateTime(2026, 8, 20, 17, 32)),
    ]);

    final forecast = service.forecast(route);
    expect(forecast, isNotNull);
    expect(forecast!.confidence, 'High');
    expect(forecast.forecastPace.isFinite, isTrue);
    expect(forecast.projectedFinish.isAfter(route.checkpoints.last.timestamp), isTrue);
    expect(forecast.projectedFinish.isBefore(DateTime(2026, 8, 20, 20, 0)), isTrue);
  });

  test('long-travel lower-stop route is forecast from delivery time, not pre-route drive', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 13),
      startingStops: 125,
      startingLocations: 0,
      startingPackages: 0,
      firstStopTime: DateTime(2026, 8, 13, 11, 11),
    );
    route.checkpoints.addAll([
      Checkpoint(stopNumber: 1, timestamp: DateTime(2026, 8, 13, 11, 11)),
      Checkpoint(stopNumber: 15, timestamp: DateTime(2026, 8, 13, 12, 18)),
      Checkpoint(stopNumber: 40, timestamp: DateTime(2026, 8, 13, 13, 11)),
      Checkpoint(stopNumber: 62, timestamp: DateTime(2026, 8, 13, 14, 10)),
      Checkpoint(stopNumber: 81, timestamp: DateTime(2026, 8, 13, 15, 11)),
      Checkpoint(stopNumber: 94, timestamp: DateTime(2026, 8, 13, 16, 12)),
      Checkpoint(stopNumber: 106, timestamp: DateTime(2026, 8, 13, 17, 13)),
    ]);

    final forecast = service.forecast(route);
    expect(forecast, isNotNull);
    expect(forecast!.confidence, 'High');
    expect(forecast.forecastPace.isFinite, isTrue);
    expect(forecast.projectedFinish.isAfter(route.checkpoints.last.timestamp), isTrue);
    expect(forecast.projectedFinish.isBefore(DateTime(2026, 8, 13, 20, 0)), isTrue);
  });

  test('stops remaining never becomes negative', () {
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 100,
      startingLocations: 0,
      startingPackages: 0,
      firstStopTime: DateTime(2026, 8, 20, 10),
    );
    route.checkpoints.add(Checkpoint(stopNumber: 105, timestamp: DateTime(2026, 8, 20, 15)));
    expect(route.stopsRemaining, 0);
    expect(service.forecast(route), isNull);
  });
}
