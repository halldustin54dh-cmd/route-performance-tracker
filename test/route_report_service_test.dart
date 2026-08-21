import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/checkpoint.dart';
import 'package:route_performance_tracker/models/delivery_route.dart';
import 'package:route_performance_tracker/models/route_event.dart';
import 'package:route_performance_tracker/services/route_report_service.dart';

void main() {
  test('route report includes pace, checkpoints, and delays', () {
    final first = DateTime(2026, 8, 20, 10, 0);
    final route = DeliveryRoute(
      date: DateTime(2026, 8, 20),
      startingStops: 100,
      startingLocations: 120,
      startingPackages: 180,
      firstStopTime: first,
      finalStopTime: first.add(const Duration(hours: 5)),
      checkpoints: [
        Checkpoint(stopNumber: 1, timestamp: first),
        Checkpoint(stopNumber: 100, timestamp: first.add(const Duration(hours: 5))),
      ],
      events: [
        RouteEvent(
          type: RouteEventType.wrongAddress,
          timestamp: first.add(const Duration(hours: 2)),
          stopNumber: 40,
          delayMinutes: 10,
          notes: 'Navigation issue',
        ),
      ],
    );

    final text = const RouteReportService().buildText(route);

    expect(text, contains('ROUTE PERFORMANCE REPORT'));
    expect(text, contains('Stop 100'));
    expect(text, contains('Wrong Address'));
    expect(text, contains('10 min delay'));
    expect(text, contains('Adjusted pace'));
  });
}
