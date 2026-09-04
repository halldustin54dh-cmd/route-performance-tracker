import '../models/checkpoint.dart';
import '../models/delivery_route.dart';
import '../models/route_event.dart';
import 'route_repository.dart';

class HistoricalRouteSeedService {
  const HistoricalRouteSeedService._();

  static DateTime _at(int day, int hour, int minute) => DateTime(2026, 8, day, hour, minute);

  static Checkpoint _cp(int day, int stop, int hour, int minute) => Checkpoint(
        stopNumber: stop,
        timestamp: _at(day, hour, minute),
      );

  static List<DeliveryRoute> _routes() => [
        DeliveryRoute(
          date: DateTime(2026, 8, 13),
          startingStops: 125,
          startingLocations: 0,
          startingPackages: 0,
          firstStopTime: _at(13, 11, 11),
          finalStopTime: _at(13, 18, 28),
          routeType: 'Mixed',
          checkpoints: [
            _cp(13, 1, 11, 11),
            _cp(13, 15, 12, 18),
            _cp(13, 40, 13, 11),
            _cp(13, 62, 14, 10),
            _cp(13, 81, 15, 11),
            _cp(13, 94, 16, 12),
            _cp(13, 106, 17, 13),
            _cp(13, 125, 18, 28),
          ],
        ),
        DeliveryRoute(
          date: DateTime(2026, 8, 14),
          startingStops: 193,
          startingLocations: 0,
          startingPackages: 0,
          firstStopTime: _at(14, 10, 33),
          finalStopTime: _at(14, 18, 22),
          routeType: 'Mixed',
          historicalAdjustedPace: 17.16,
          checkpoints: [
            _cp(14, 1, 10, 33),
            _cp(14, 36, 11, 33),
            _cp(14, 49, 12, 33),
            _cp(14, 77, 13, 33),
            _cp(14, 95, 14, 38),
            _cp(14, 147, 16, 42),
            _cp(14, 168, 17, 32),
            _cp(14, 193, 18, 22),
          ],
          events: [
            RouteEvent(
              type: RouteEventType.custom,
              timestamp: _at(14, 12, 33),
              stopNumber: 49,
              delayMinutes: 9,
              notes: 'Backtracking / business location issue.',
            ),
            RouteEvent(
              type: RouteEventType.custom,
              timestamp: _at(14, 18, 17),
              stopNumber: 193,
              delayMinutes: 5,
              notes: 'Missing package near final stop.',
            ),
          ],
        ),
        DeliveryRoute(
          date: DateTime(2026, 8, 15),
          startingStops: 166,
          startingLocations: 0,
          startingPackages: 0,
          firstStopTime: _at(15, 10, 58),
          finalStopTime: _at(15, 19, 43),
          routeType: 'Mixed',
          checkpoints: [
            _cp(15, 1, 10, 58),
            _cp(15, 16, 12, 0),
            _cp(15, 36, 13, 3),
            _cp(15, 47, 14, 1),
            _cp(15, 70, 15, 0),
            _cp(15, 81, 15, 34),
            _cp(15, 82, 15, 49),
            _cp(15, 84, 16, 0),
            _cp(15, 96, 17, 0),
            _cp(15, 110, 18, 7),
            _cp(15, 142, 19, 1),
            _cp(15, 166, 19, 43),
          ],
          events: [
            RouteEvent(
              type: RouteEventType.construction,
              timestamp: _at(15, 15, 49),
              stopNumber: 82,
              notes: 'Road closures documented on route.',
            ),
          ],
        ),
        DeliveryRoute(
          date: DateTime(2026, 8, 20),
          startingStops: 184,
          startingLocations: 0,
          startingPackages: 0,
          firstStopTime: _at(20, 10, 47),
          finalStopTime: _at(20, 18, 44),
          routeType: 'Mixed',
          historicalAdjustedPace: 20.93,
          checkpoints: [
            _cp(20, 1, 10, 47),
            _cp(20, 33, 11, 47),
            _cp(20, 47, 13, 4),
            _cp(20, 57, 13, 50),
            _cp(20, 77, 14, 50),
            _cp(20, 103, 15, 50),
            _cp(20, 130, 16, 54),
            _cp(20, 157, 17, 54),
            _cp(20, 184, 18, 44),
          ],
          events: [
            RouteEvent(
              type: RouteEventType.wrongAddress,
              timestamp: _at(20, 12, 54),
              stopNumber: 46,
              delayMinutes: 10,
              notes: 'Navigation sent driver to the wrong address.',
            ),
          ],
        ),
        DeliveryRoute(
          date: DateTime(2026, 8, 27),
          startingStops: 195,
          startingLocations: 260,
          startingPackages: 325,
          multiLocationStops: 47,
          firstStopTime: _at(27, 10, 25),
          finalStopTime: _at(27, 17, 36),
          routeType: 'Mixed',
          checkpoints: [
            _cp(27, 1, 10, 25),
            _cp(27, 28, 11, 25),
            _cp(27, 51, 12, 25),
            _cp(27, 80, 13, 24),
            _cp(27, 100, 14, 25),
            _cp(27, 123, 15, 25),
            _cp(27, 157, 16, 25),
            _cp(27, 186, 17, 24),
            // Stops 40-42 were consolidated during the route, so the final
            // numbered stop was 193 even though the route began with 195 stops.
            _cp(27, 193, 17, 36),
          ],
        ),
      ];

  static List<DeliveryRoute> missingRoutes(List<DeliveryRoute> existing) {
    final existingDates = existing
        .map((route) => DateTime(route.date.year, route.date.month, route.date.day))
        .toSet();

    return _routes()
        .where((route) => !existingDates.contains(DateTime(route.date.year, route.date.month, route.date.day)))
        .toList(growable: false);
  }

  static Future<int> seed(RouteRepository repository) async {
    final missing = missingRoutes(await repository.allRoutes());
    for (final route in missing) {
      await repository.createRoute(route);
      await repository.saveRoute(route);
    }
    return missing.length;
  }
}
