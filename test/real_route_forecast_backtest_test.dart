import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/services/route_metrics_service.dart';

import 'fixtures/real_route_fixtures.dart';

void main() {
  const metrics = RouteMetricsService();

  group('real route forecast backtests', () {
    test('every eligible historical checkpoint produces a forecast', () {
      for (final fixture in realRouteFixtures) {
        final route = fixture.route;
        for (var count = 2; count < route.checkpoints.length; count++) {
          final partial = routeThroughCheckpoint(route, count);
          final forecast = metrics.forecast(partial);
          expect(
            forecast,
            isNotNull,
            reason: '${fixture.label} should forecast after checkpoint $count',
          );
        }
      }
    });

    test('late-route forecasts are materially better than early-route forecasts', () {
      final earlyErrors = <double>[];
      final lateErrors = <double>[];

      for (final fixture in realRouteFixtures) {
        final source = fixture.route;
        final actualFinish = source.finalStopTime!;
        final errors = <double>[];

        for (var count = 2; count < source.checkpoints.length; count++) {
          final partial = routeThroughCheckpoint(source, count);
          final forecast = metrics.forecast(partial)!;
          final errorMinutes = forecast.projectedFinish.difference(actualFinish).inSeconds.abs() / 60.0;
          errors.add(errorMinutes);
        }

        earlyErrors.addAll(errors.take(2));
        lateErrors.addAll(errors.skip(errors.length > 3 ? errors.length - 3 : 0));
      }

      final earlyMae = earlyErrors.reduce((a, b) => a + b) / earlyErrors.length;
      final lateMae = lateErrors.reduce((a, b) => a + b) / lateErrors.length;

      // This is intentionally a behavior benchmark rather than a claim that the
      // current algorithm is already accurate enough for production. The real
      // routes show that forecasts stabilize as more checkpoint data arrives.
      expect(lateMae, lessThan(earlyMae));
      expect(lateMae, lessThan(60));
    });

    test('prints a checkpoint-by-checkpoint accuracy report for tuning', () {
      final allErrors = <double>[];

      for (final fixture in realRouteFixtures) {
        final source = fixture.route;
        final actualFinish = source.finalStopTime!;
        final routeErrors = <double>[];

        // ignore: avoid_print
        print('\n${fixture.label} | actual ${_clock(actualFinish)} | ${source.startingStops} stops');

        for (var count = 2; count < source.checkpoints.length; count++) {
          final partial = routeThroughCheckpoint(source, count);
          final checkpoint = partial.checkpoints.last;
          final forecast = metrics.forecast(partial)!;
          final signedError = forecast.projectedFinish.difference(actualFinish).inSeconds / 60.0;
          final absoluteError = signedError.abs();
          routeErrors.add(absoluteError);
          allErrors.add(absoluteError);

          // ignore: avoid_print
          print(
            '  stop ${checkpoint.stopNumber.toString().padLeft(3)} @ ${_clock(checkpoint.timestamp)}'
            ' -> ${_clock(forecast.projectedFinish)}'
            ' | ${_signedMinutes(signedError)}'
            ' | ${forecast.confidence}',
          );
        }

        final mae = routeErrors.reduce((a, b) => a + b) / routeErrors.length;
        // ignore: avoid_print
        print('  route MAE: ${mae.toStringAsFixed(1)} min');
      }

      final overallMae = allErrors.reduce((a, b) => a + b) / allErrors.length;
      // ignore: avoid_print
      print('\nOverall checkpoint MAE: ${overallMae.toStringAsFixed(1)} min');

      // Keep this broad on purpose. This test primarily guarantees the report
      // remains executable while we improve the forecasting model.
      expect(overallMae, lessThan(120));
    });
  });
}

String _clock(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}

String _signedMinutes(double value) {
  final rounded = value.round();
  if (rounded == 0) return 'exact';
  return '${rounded > 0 ? '+' : ''}$rounded min';
}
