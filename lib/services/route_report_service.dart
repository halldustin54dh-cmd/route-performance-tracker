import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/delivery_route.dart';
import 'route_difficulty_service.dart';
import 'route_metrics_service.dart';

class RouteReportService {
  const RouteReportService();

  static const _metrics = RouteMetricsService();
  static const _difficulty = RouteDifficultyService();

  String buildText(DeliveryRoute route) {
    final raw = _metrics.rawPace(route);
    final adjusted = _metrics.adjustedPace(route);
    final duration = _metrics.routeDuration(route);
    final difficulty = _difficulty.calculate(route);
    final buffer = StringBuffer();

    buffer.writeln('ROUTE PERFORMANCE REPORT');
    buffer.writeln(_date(route.date));
    buffer.writeln();
    buffer.writeln('ROUTE SUMMARY');
    buffer.writeln('Route type: ${route.routeType}');
    buffer.writeln('Starting stops: ${route.startingStops}');
    if (route.startingLocations > 0) buffer.writeln('Starting locations: ${route.startingLocations}');
    if (route.startingPackages > 0) buffer.writeln('Starting packages: ${route.startingPackages}');
    buffer.writeln('First stop: ${_time(route.firstStopTime)}');
    buffer.writeln('Final stop: ${_time(route.finalStopTime)}');
    if (duration != null) {
      buffer.writeln('Delivery duration: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m');
    }
    buffer.writeln('Raw pace: ${_pace(raw)}');
    buffer.writeln('Adjusted pace: ${_pace(adjusted)}');
    buffer.writeln('Documented delay: ${route.documentedDelayMinutes} min');
    buffer.writeln('Difficulty: ${difficulty?.score.toStringAsFixed(0) ?? 'Not enough data'}${difficulty == null ? '' : ' / 100 (${difficulty.band})'}');
    buffer.writeln();

    buffer.writeln('CHECKPOINTS');
    if (route.checkpoints.isEmpty) {
      buffer.writeln('None recorded');
    } else {
      for (final checkpoint in route.checkpoints) {
        buffer.writeln('Stop ${checkpoint.stopNumber} — ${_time(checkpoint.timestamp)}');
      }
    }
    buffer.writeln();

    buffer.writeln('EVENTS / DELAYS');
    if (route.events.isEmpty) {
      buffer.writeln('None recorded');
    } else {
      for (final event in route.events) {
        final parts = <String>[
          _time(event.timestamp),
          if (event.stopNumber != null) 'Stop ${event.stopNumber}',
          event.type.label,
          if (event.delayMinutes > 0) '${event.delayMinutes} min delay',
          if (event.notes.trim().isNotEmpty) event.notes.trim(),
        ];
        buffer.writeln(parts.join(' • '));
      }
    }
    buffer.writeln();

    buffer.writeln('EVIDENCE');
    if (route.evidence.isEmpty) {
      buffer.writeln('None recorded');
    } else {
      for (final item in route.evidence) {
        final parts = <String>[
          _time(item.timestamp),
          if (item.stopNumber != null) 'Stop ${item.stopNumber}',
          item.type.label,
          item.suggestedFileName,
          if (item.caption.trim().isNotEmpty) item.caption.trim(),
          item.filePath,
        ];
        buffer.writeln(parts.join(' • '));
      }
    }

    return buffer.toString().trimRight();
  }

  Future<File> exportTextFile(DeliveryRoute route) async {
    final directory = await getApplicationDocumentsDirectory();
    final reports = Directory('${directory.path}/route_reports');
    if (!await reports.exists()) await reports.create(recursive: true);
    final file = File('${reports.path}/${_fileName(route.date)}');
    return file.writeAsString(buildText(route), flush: true);
  }

  String _fileName(DateTime date) =>
      'Route_Report_${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.txt';

  String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';

  String _time(DateTime? value) {
    if (value == null) return '—';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _pace(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} stops/hr';
}
