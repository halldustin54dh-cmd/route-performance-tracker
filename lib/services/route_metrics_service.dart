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

  double? _rollingRecentPace(DeliveryRoute route) {
    if (route.checkpoints.length < 2) return null;

    // Use up to the last three checkpoints so one weird stop or short segment
    // cannot completely hijack the projected finish time.
    final latestIndex = route.checkpoints.length - 1;
    final startIndex = (latestIndex - 2).clamp(0, latestIndex).toInt();
    final first = route.checkpoints[startIndex];
    final latest = route.checkpoints[latestIndex];
    final stops = latest.stopNumber - first.stopNumber;
    if (stops <= 0) return null;

    final elapsedMinutes = latest.timestamp.difference(first.timestamp).inMinutes;
    final inWindowDelay = route.events
        .where((event) => event.timestamp.isAfter(first.timestamp) && !event.timestamp.isAfter(latest.timestamp))
        .fold<int>(0, (sum, event) => sum + event.delayMinutes);
    final activeMinutes = elapsedMinutes - inWindowDelay;
    if (activeMinutes <= 0) return null;

    return stops / (activeMinutes / 60);
  }

  RouteForecast? forecast(DeliveryRoute route) {
    if (route.checkpoints.length < 2 || route.stopsRemaining <= 0) return null;

    final cumulative = adjustedPace(route);
    final rollingRecent = _rollingRecentPace(route);
    if (cumulative == null || rollingRecent == null || cumulative <= 0 || rollingRecent <= 0) return null;

    // Real-route backtests showed that an unusually slow or fast short segment
    // can move the old forecast by hours. Keep recent pace useful, but bounded
    // relative to the much more stable cumulative pace.
    final recentFloor = cumulative * 0.70;
    final recentCeiling = cumulative * 1.30;
    final recent = rollingRecent.clamp(recentFloor, recentCeiling).toDouble();

    final history = route.historicalAdjustedPace;
    final double pace;
    final String method;

    if (history != null && history > 0) {
      pace = (0.7 * cumulative) + (0.1 * recent) + (0.2 * history);
      method = '70% adjusted cumulative + 10% smoothed recent + 20% 30-day history';
    } else {
      pace = (0.875 * cumulative) + (0.125 * recent);
      method = '87.5% adjusted cumulative + 12.5% smoothed recent';
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
