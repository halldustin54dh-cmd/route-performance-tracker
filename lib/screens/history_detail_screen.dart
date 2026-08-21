import 'package:flutter/material.dart';
import '../models/delivery_route.dart';
import '../services/route_metrics_service.dart';
import '../widgets/metric_tile.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.route});

  final DeliveryRoute route;
  static const _metrics = RouteMetricsService();

  String _time(DateTime? value) {
    if (value == null) return '—';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _pace(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)}/hr';

  @override
  Widget build(BuildContext context) {
    final raw = _metrics.rawPace(route);
    final adjusted = _metrics.adjustedPace(route);
    final duration = _metrics.routeDuration(route);
    final durationText = duration == null ? '—' : '${duration.inMinutes ~/ 60}h ${duration.inMinutes % 60}m';

    return Scaffold(
      appBar: AppBar(title: Text('${route.date.month}/${route.date.day}/${route.date.year} Route')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              MetricTile(label: 'Stops', value: '${route.startingStops}', icon: Icons.pin_drop_outlined),
              MetricTile(label: 'Duration', value: durationText, icon: Icons.schedule),
              MetricTile(label: 'Raw pace', value: _pace(raw), icon: Icons.speed),
              MetricTile(label: 'Adjusted pace', value: _pace(adjusted), helper: '${route.documentedDelayMinutes} min documented delay', icon: Icons.tune),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text('Type: ${route.routeType}'),
                  Text('First stop: ${_time(route.firstStopTime)}'),
                  Text('Final stop: ${_time(route.finalStopTime)}'),
                  Text('Checkpoints: ${route.checkpoints.length}'),
                  Text('Events: ${route.events.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...route.checkpoints.map((checkpoint) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
                  title: Text('Stop ${checkpoint.stopNumber}'),
                  subtitle: Text(_time(checkpoint.timestamp)),
                ),
              )),
          ...route.events.map((event) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.report_outlined)),
                  title: Text(event.type.label),
                  subtitle: Text([
                    _time(event.timestamp),
                    if (event.stopNumber != null) 'Stop ${event.stopNumber}',
                    if (event.delayMinutes > 0) '${event.delayMinutes} min delay',
                    if (event.notes.isNotEmpty) event.notes,
                  ].join(' • ')),
                ),
              )),
        ],
      ),
    );
  }
}
