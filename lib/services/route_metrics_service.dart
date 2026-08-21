import '../models/delivery_route.dart';

class RouteForecast {
  const RouteForecast({
    required this.forecastPace,
    required this.projectedFinish,
    required this.confidence,
    required this.method,
  });

  final double forecastPace;
  final DateTime projectedFinish;
  final String confidence;
  final String method;
}

class RouteMetricsService {
  const RouteMetricsService();

  double? cumulativePace(DeliveryRoute route) {
    final firstStop = route.firstStopTime;
    if (firstStop == null || route.checkpoints.isEmpty) return null;
    final latest = route.checkpoints.last;
    final elapsedHours = latest.timestamp.difference(firstStop).inSeconds / 3600;
    if (elapsedHours <= 0) return null;
    return latest.stopNumber / elapsedHours;
  }

  double? latestSegmentPace(DeliveryRoute route) {
    if (route.checkpoints.length < 2) return null;
    final current = route.checkpoints.last;
    final previous = route.checkpoints[route.checkpoints.length - 2];
    final stops = current.stopNumber - previous.stopNumber;
    final elapsedHours = current.timestamp.difference(previous.timestamp).inSeconds / 3600;
    if (stops <= 0 || elapsedHours <= 0) return null;
    return stops / elapsedHours;
  }

  double? rawPace(DeliveryRoute route) => cumulativePace(route);

  double? adjustedPace(DeliveryRoute route) {
    final firstStop = route.firstStopTime;
    if (firstStop == null || route.checkpoints.isEmpty) return null;
    final latest = route.checkpoints.last;
    final elapsedMinutes = latest.timestamp.difference(firstStop).inMinutes;
    final inWindowDelay = route.events
        .where((event) => !event.timestamp.isBefore(firstStop) && !event.timestamp.isAfter(latest.timestamp))
        .fold<int>(0, (sum, event) => sum + event.delayMinutes);
    final activeMinutes = elapsedMinutes - inWindowDelay;
    if (activeMinutes <= 0) return null;
    return latest.stopNumber / (activeMinutes / 60);
  }

  Duration? routeDuration(DeliveryRoute route) {
    final first = route.firstStopTime;
    final last = route.finalStopTime;
    if (first == null || last == null) return null;
    return last.difference(first);
  }

  RouteForecast? forecast(DeliveryRoute route) {
    if (route.checkpoints.length < 2 || route.stopsRemaining <= 0) return null;

    final cumulative = cumulativePace(route);
    final recent = latestSegmentPace(route);
    if (cumulative == null || recent == null || cumulative <= 0 || recent <= 0) return null;

    final history = route.historicalAdjustedPace;
    final double pace;
    final String method;

    if (history != null && history > 0) {
      pace = (0.5 * cumulative) + (0.3 * recent) + (0.2 * history);
      method = '50% cumulative + 30% recent + 20% 30-day history';
    } else {
      pace = (0.6 * cumulative) + (0.4 * recent);
      method = '60% cumulative + 40% recent';
    }

    final remainingMinutes = (route.stopsRemaining / pace * 60).round();
    final finish = route.checkpoints.last.timestamp.add(Duration(minutes: remainingMinutes));

    final count = route.checkpoints.length;
    final confidence = count == 2 ? 'Low' : count <= 4 ? 'Medium' : 'High';

    return RouteForecast(
      forecastPace: pace,
      projectedFinish: finish,
      confidence: confidence,
      method: method,
    );
  }
}
