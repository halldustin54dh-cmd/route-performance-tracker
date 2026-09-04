import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/delivery_route.dart';
import 'package:route_performance_tracker/services/historical_route_seed_service.dart';
import 'package:route_performance_tracker/services/route_difficulty_service.dart';

void main() {
  group('HistoricalRouteSeedService', () {
    test('returns only historical routes that are not already stored', () {
      final existing = [
        DeliveryRoute(
          date: DateTime(2026, 8, 14),
          startingStops: 193,
          startingLocations: 0,
          startingPackages: 0,
        ),
      ];

      final missing = HistoricalRouteSeedService.missingRoutes(existing);

      expect(missing.map((route) => route.date), contains(DateTime(2026, 8, 13)));
      expect(missing.map((route) => route.date), isNot(contains(DateTime(2026, 8, 14))));
      expect(missing.map((route) => route.date), contains(DateTime(2026, 8, 15)));
      expect(missing.map((route) => route.date), contains(DateTime(2026, 8, 20)));
      expect(missing.map((route) => route.date), contains(DateTime(2026, 8, 27)));
    });

    test('historical routes are completed and preserve documented checkpoints', () {
      final routes = HistoricalRouteSeedService.missingRoutes(const []);

      expect(routes, hasLength(5));
      for (final route in routes) {
        expect(route.finalStopTime, isNotNull);
        expect(route.checkpoints, isNotEmpty);
        expect(route.checkpoints.first.stopNumber, 1);
        expect(route.checkpoints.last.stopNumber, lessThanOrEqualTo(route.startingStops));
      }
    });

    test('Aug 27 seed preserves documented workload and consolidated stop history', () {
      const difficulty = RouteDifficultyService();
      final route = HistoricalRouteSeedService.missingRoutes(const [])
          .singleWhere((route) => route.date == DateTime(2026, 8, 27));

      expect(route.startingStops, 195);
      expect(route.startingLocations, 260);
      expect(route.startingPackages, 325);
      expect(route.multiLocationStops, 47);
      expect(route.checkpoints.last.stopNumber, 193);
      expect(route.finalStopTime, DateTime(2026, 8, 27, 17, 36));
      expect(difficulty.calculate(route), isNotNull);
    });
  });
}
