import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/delivery_route.dart';
import '../services/route_metrics_service.dart';
import '../services/route_report_service.dart';
import '../services/route_repository.dart';
import '../widgets/metric_tile.dart';
import 'activity_editor_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.route,
    required this.repository,
  });

  final DeliveryRoute route;
  final RouteRepository repository;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  static const _metrics = RouteMetricsService();
  static const _reports = RouteReportService();

  DeliveryRoute get route => widget.route;

  String _time(DateTime? value) {
    if (value == null) return '—';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _pace(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)}/hr';

  Future<void> _copyReport() async {
    await Clipboard.setData(ClipboardData(text: _reports.buildText(route)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route report copied to clipboard.')));
  }

  Future<void> _exportReport() async {
    final file = await _reports.exportTextFile(route);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to ${file.path}')));
  }

  Future<void> _openCorrections() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityEditorScreen(route: route, repository: widget.repository),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final raw = _metrics.rawPace(route);
    final adjusted = _metrics.adjustedPace(route);
    final duration = _metrics.routeDuration(route);
    final durationText = duration == null ? '—' : '${duration.inMinutes ~/ 60}h ${duration.inMinutes % 60}m';

    return Scaffold(
      appBar: AppBar(
        title: Text('${route.date.month}/${route.date.day}/${route.date.year} Route'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') _copyReport();
              if (value == 'export') _exportReport();
              if (value == 'correct') _openCorrections();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('Copy report')),
              PopupMenuItem(value: 'export', child: Text('Export report file')),
              PopupMenuItem(value: 'correct', child: Text('Correct checkpoints/events')),
            ],
          ),
        ],
      ),
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
              MetricTile(
                label: 'Adjusted pace',
                value: _pace(adjusted),
                helper: '${route.documentedDelayMinutes} min documented delay',
                icon: Icons.tune,
              ),
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
                  Text('Evidence items: ${route.evidence.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openCorrections,
            icon: const Icon(Icons.edit_note),
            label: const Text('Correct Route Activity'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _copyReport,
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy Route Report'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export Report File'),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 20),
          Text('Evidence', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (route.evidence.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No evidence captured for this route.')))
          else
            ...route.evidence.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.photo_outlined)),
                    title: Text(item.type.label),
                    subtitle: Text([
                      _time(item.timestamp),
                      if (item.stopNumber != null) 'Stop ${item.stopNumber}',
                      item.suggestedFileName,
                      if (item.caption.isNotEmpty) item.caption,
                    ].join(' • ')),
                  ),
                )),
        ],
      ),
    );
  }
}
