import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/checkpoint.dart';
import '../models/delivery_route.dart';
import '../models/route_event.dart';
import '../models/route_evidence.dart';
import '../services/route_metrics_service.dart';
import '../services/route_difficulty_service.dart';
import '../services/evidence_storage_service.dart';
import '../services/route_repository.dart';
import '../widgets/metric_tile.dart';

class LiveRouteScreen extends StatefulWidget {
  const LiveRouteScreen({
    super.key,
    required this.route,
    required this.repository,
  });

  final DeliveryRoute route;
  final RouteRepository repository;

  @override
  State<LiveRouteScreen> createState() => _LiveRouteScreenState();
}

class _LiveRouteScreenState extends State<LiveRouteScreen> {
  final _metrics = const RouteMetricsService();
  final _difficulty = const RouteDifficultyService();
  final _evidenceStorage = const EvidenceStorageService();
  final _picker = ImagePicker();
  bool _saving = false;

  String _time(DateTime? value) {
    if (value == null) return '—';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _pace(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)}/hr';

  Future<void> _persist() async {
    if (_saving) return;
    _saving = true;
    try {
      await widget.repository.saveRoute(widget.route);
    } finally {
      _saving = false;
    }
  }

  Future<void> _beginFirstStop() async {
    if (widget.route.hasStarted) return;
    final now = DateTime.now();
    setState(() {
      widget.route.firstStopTime = now;
      widget.route.checkpoints.add(Checkpoint(stopNumber: 1, timestamp: now));
      if (widget.route.startingStops == 1) widget.route.finalStopTime = now;
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('First stop recorded at ${_time(now)}.')),
    );
  }

  Future<void> _addCheckpoint() async {
    if (!widget.route.hasStarted || widget.route.isComplete) return;
    final controller = TextEditingController();

    final stop = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add checkpoint'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current stop #',
            helperText: 'Time will be captured automatically.',
            hintText: '${widget.route.currentStop + 1}',
          ),
          onSubmitted: (_) => Navigator.pop(context, int.tryParse(controller.text)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (stop == null) return;
    if (stop <= widget.route.currentStop || stop > widget.route.startingStops) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a stop between ${widget.route.currentStop + 1} and ${widget.route.startingStops}.')),
      );
      return;
    }

    final now = DateTime.now();
    setState(() {
      widget.route.checkpoints.add(Checkpoint(stopNumber: stop, timestamp: now));
      if (stop == widget.route.startingStops) widget.route.finalStopTime = now;
    });
    await _persist();

    if (!mounted) return;
    if (widget.route.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route complete at ${_time(now)}. Saved to History.')),
      );
    }
  }

  Future<void> _addEvent() async {
    RouteEventType selected = RouteEventType.bathroom;
    final delayController = TextEditingController();
    final noteController = TextEditingController();

    final event = await showModalBottomSheet<RouteEvent>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add route event', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<RouteEventType>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Event type'),
                items: RouteEventType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                    .toList(),
                onChanged: (value) => setSheetState(() => selected = value ?? selected),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: delayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delay minutes',
                  hintText: '0',
                  helperText: 'Used for adjusted pace during the delivery window.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    RouteEvent(
                      type: selected,
                      timestamp: DateTime.now(),
                      stopNumber: widget.route.currentStop == 0 ? null : widget.route.currentStop,
                      delayMinutes: int.tryParse(delayController.text.trim()) ?? 0,
                      notes: noteController.text.trim(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    delayController.dispose();
    noteController.dispose();

    if (event != null) {
      setState(() => widget.route.events.add(event));
      await _persist();
    }
  }

  Future<void> _addEvidence() async {
    if (widget.route.id == null) return;
    EvidenceType selectedType = EvidenceType.routeDocumentation;
    final captionController = TextEditingController();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose screenshot / photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 92);
    if (picked == null || !mounted) return;

    final details = await showModalBottomSheet<({EvidenceType type, String caption})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Save route evidence', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<EvidenceType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Evidence type'),
                items: EvidenceType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                onChanged: (value) => setSheetState(() => selectedType = value ?? selectedType),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'What does this show?'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, (type: selectedType, caption: captionController.text.trim())),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save Evidence')),
              ),
            ],
          ),
        ),
      ),
    );
    captionController.dispose();
    if (details == null) return;

    final now = DateTime.now();
    final stop = widget.route.currentStop == 0 ? null : widget.route.currentStop;
    final relatedEvent = widget.route.events.isEmpty ? null : widget.route.events.last.type.label;
    final draft = RouteEvidence(
      filePath: picked.path,
      timestamp: now,
      type: details.type,
      stopNumber: stop,
      caption: details.caption,
      relatedEventType: details.type == EvidenceType.incidentEvidence ? relatedEvent : null,
    );
    final storedPath = await _evidenceStorage.persistImage(
      sourcePath: picked.path,
      suggestedBaseName: draft.suggestedFileName,
    );
    final saved = RouteEvidence(
      filePath: storedPath,
      timestamp: now,
      type: details.type,
      stopNumber: stop,
      caption: details.caption,
      relatedEventType: draft.relatedEventType,
    );
    setState(() => widget.route.evidence.add(saved));
    await _persist();
  }

  Future<void> _deleteRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this route?'),
        content: const Text('This removes the route, checkpoints, and events stored on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || widget.route.id == null) return;
    await widget.repository.deleteRoute(widget.route.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final raw = _metrics.rawPace(route);
    final adjusted = _metrics.adjustedPace(route);
    final segment = _metrics.latestSegmentPace(route);
    final forecast = _metrics.forecast(route);
    final progress = route.startingStops == 0 ? 0.0 : route.currentStop / route.startingStops;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Route'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteRoute();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete route')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (!route.hasStarted) ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.flag_outlined, size: 40, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(height: 12),
                      Text('Route setup is saved', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      const Text('Do not start the delivery clock until you are actually at your first delivery stop.', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _beginFirstStop,
                        icon: const Icon(Icons.timer_outlined),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Record First Stop Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              color: const Color(0xFF172033),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            !route.hasStarted
                                ? '${route.startingStops} stops ready'
                                : route.isComplete
                                    ? 'Route complete'
                                    : 'Stop ${route.currentStop} of ${route.startingStops}',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Chip(
                          avatar: Icon(route.isComplete ? Icons.check_circle : Icons.route, size: 18),
                          label: Text(route.isComplete ? 'Complete' : route.routeType),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 14),
                    Text('${route.stopsRemaining} stops remaining', style: const TextStyle(color: Colors.white70)),
                    if (route.historicalAdjustedPace != null) ...[
                      const SizedBox(height: 4),
                      Text('30-day baseline ${route.historicalAdjustedPace!.toStringAsFixed(1)}/hr', style: const TextStyle(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                MetricTile(label: 'Raw pace', value: _pace(raw), icon: Icons.speed),
                MetricTile(label: 'Adjusted pace', value: _pace(adjusted), helper: '${route.documentedDelayMinutes} min documented', icon: Icons.tune),
                MetricTile(label: 'Latest segment', value: _pace(segment), icon: Icons.timeline),
                MetricTile(
                  label: 'Projected finish',
                  value: _time(forecast?.projectedFinish),
                  helper: !route.hasStarted
                      ? 'Start at first stop'
                      : forecast == null
                          ? 'Add checkpoint 2'
                          : '${forecast.confidence} confidence',
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
            if (forecast != null) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_graph, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Forecast pace ${forecast.forecastPace.toStringAsFixed(1)}/hr', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(forecast.method),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final value = _difficulty.calculate(route);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: value == null
                        ? const Row(
                            children: [
                              Icon(Icons.query_stats_outlined),
                              SizedBox(width: 12),
                              Expanded(child: Text('Route difficulty: Not enough data. Add locations, packages, and optional route context during setup.')),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.route_outlined),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Difficulty ${value.score.toStringAsFixed(0)}/100 · ${value.band}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Workload ${value.workload.toStringAsFixed(0)} · Complexity/travel ${value.complexityTravel.toStringAsFixed(0)} · Context ${value.context.toStringAsFixed(0)}'),
                            ],
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Route activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (route.checkpoints.isEmpty && route.events.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No activity yet. Route setup is stored, but delivery timing has not started.'),
                ),
              ),
            ..._activityItems(route),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Add event',
              onPressed: route.isComplete ? null : _addEvent,
              icon: const Icon(Icons.add_alert_outlined),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add evidence',
              onPressed: _addEvidence,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: !route.hasStarted || route.isComplete ? null : _addCheckpoint,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(route.isComplete ? 'Route Complete' : 'Add Checkpoint'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activityItems(DeliveryRoute route) {
    final entries = <({DateTime time, Widget tile})>[];

    for (final checkpoint in route.checkpoints) {
      entries.add((
        time: checkpoint.timestamp,
        tile: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
          title: Text(checkpoint.stopNumber == 1 ? 'First stop' : 'Stop ${checkpoint.stopNumber} checkpoint'),
          subtitle: Text(_time(checkpoint.timestamp)),
        ),
      ));
    }

    for (final event in route.events) {
      entries.add((
        time: event.timestamp,
        tile: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.report_outlined)),
          title: Text(event.type.label),
          subtitle: Text([
            _time(event.timestamp),
            if (event.stopNumber != null) 'Stop ${event.stopNumber}',
            if (event.delayMinutes > 0) '${event.delayMinutes} min delay',
            if (event.notes.isNotEmpty) event.notes,
          ].join(' • ')),
        ),
      ));
    }

    for (final item in route.evidence) {
      entries.add((
        time: item.timestamp,
        tile: ListTile(
          leading: CircleAvatar(
            backgroundImage: File(item.filePath).existsSync() ? FileImage(File(item.filePath)) : null,
            child: File(item.filePath).existsSync() ? null : const Icon(Icons.image_not_supported_outlined),
          ),
          title: Text(item.type.label),
          subtitle: Text([
            _time(item.timestamp),
            if (item.stopNumber != null) 'Stop ${item.stopNumber}',
            item.suggestedFileName,
            if (item.caption.isNotEmpty) item.caption,
          ].join(' • ')),
        ),
      ));
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries
        .map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: entry.tile,
            ))
        .toList();
  }
}
