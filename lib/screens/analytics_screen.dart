import 'package:flutter/material.dart';
import '../models/delivery_route.dart';
import '../services/route_difficulty_service.dart';
import '../services/route_metrics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.routes});
  final List<DeliveryRoute> routes;

  static const _metrics = RouteMetricsService();
  static const _difficulty = RouteDifficultyService();

  List<DeliveryRoute> _window(int days) {
    if (routes.isEmpty) return const [];
    final latest = routes.map((r) => r.date).reduce((a,b) => a.isAfter(b) ? a : b);
    final start = latest.subtract(Duration(days: days - 1));
    return routes.where((r) => !r.date.isBefore(start) && !r.date.isAfter(latest)).toList();
  }

  double? _avg(Iterable<double?> values) {
    final valid = values.whereType<double>().where((v) => v > 0).toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a,b) => a+b) / valid.length;
  }

  String _pace(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}/hr';
  String _num(double? v) => v == null ? '—' : v.toStringAsFixed(1);

  Widget _summaryCard(BuildContext context, String title, List<DeliveryRoute> data) {
    final adjusted = _avg(data.map(_metrics.adjustedPace));
    final raw = _avg(data.map(_metrics.rawPace));
    final difficulty = _avg(data.map((r) => _difficulty.calculate(r)?.score));
    final delays = data.fold<int>(0, (sum, r) => sum + r.documentedDelayMinutes);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 18, runSpacing: 10, children: [
            _stat('Routes', '${data.length}'),
            _stat('Raw pace', _pace(raw)),
            _stat('Adjusted', _pace(adjusted)),
            _stat('Difficulty', _num(difficulty)),
            _stat('Delay', '$delays min'),
          ]),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => SizedBox(
    width: 105,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final last7 = _window(7);
    final last30 = _window(30);
    final eventCounts = <String,int>{};
    for (final route in last30) {
      for (final event in route.events) {
        eventCounts.update(event.type.label, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final eventList = eventCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Your own route history, not a universal pace fantasy.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        if (routes.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Complete a route to start building analytics.')))
        else ...[
          _summaryCard(context, 'Last 7 days', last7),
          const SizedBox(height: 12),
          _summaryCard(context, 'Last 30 days', last30),
          const SizedBox(height: 12),
          _summaryCard(context, 'All time', routes),
          const SizedBox(height: 24),
          Text('Most common events · 30 days', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (eventList.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No documented events in this window.')))
          else
            ...eventList.take(8).map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.report_outlined)),
                title: Text(entry.key),
                trailing: Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            )),
        ],
      ],
    );
  }
}
