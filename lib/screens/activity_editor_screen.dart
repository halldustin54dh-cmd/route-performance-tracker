import 'package:flutter/material.dart';

import '../models/checkpoint.dart';
import '../models/delivery_route.dart';
import '../models/route_event.dart';
import '../services/route_repository.dart';

class ActivityEditorScreen extends StatefulWidget {
  const ActivityEditorScreen({
    super.key,
    required this.route,
    required this.repository,
  });

  final DeliveryRoute route;
  final RouteRepository repository;

  @override
  State<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends State<ActivityEditorScreen> {
  Future<void> _save() => widget.repository.saveRoute(widget.route);

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _editCheckpoint(int index) async {
    final current = widget.route.checkpoints[index];
    final stopController = TextEditingController(text: '${current.stopNumber}');
    var time = TimeOfDay.fromDateTime(current.timestamp);

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit checkpoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stopController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stop number'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                subtitle: Text(time.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: time);
                  if (picked != null) setDialogState(() => time = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (accepted != true) return;
    final stop = int.tryParse(stopController.text.trim());
    if (stop == null || stop < 1 || stop > widget.route.startingStops) return;

    final updatedTime = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
      time.hour,
      time.minute,
    );
    widget.route.checkpoints[index] = Checkpoint(
      id: current.id,
      stopNumber: stop,
      timestamp: updatedTime,
    );
    widget.route.checkpoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _deleteCheckpoint(int index) async {
    final checkpoint = widget.route.checkpoints[index];
    final confirmed = await _confirm('Delete checkpoint?', 'Stop ${checkpoint.stopNumber} at ${_time(checkpoint.timestamp)} will be removed.');
    if (!confirmed) return;
    widget.route.checkpoints.removeAt(index);
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _editEvent(int index) async {
    final current = widget.route.events[index];
    var type = current.type;
    final stopController = TextEditingController(text: current.stopNumber?.toString() ?? '');
    final delayController = TextEditingController(text: '${current.delayMinutes}');
    final notesController = TextEditingController(text: current.notes);

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<RouteEventType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Event type'),
                  items: RouteEventType.values
                      .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stopController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stop number (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: delayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Delay minutes'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (accepted != true) return;
    final stop = stopController.text.trim().isEmpty ? null : int.tryParse(stopController.text.trim());
    final delay = int.tryParse(delayController.text.trim()) ?? 0;
    widget.route.events[index] = RouteEvent(
      id: current.id,
      type: type,
      timestamp: current.timestamp,
      stopNumber: stop,
      delayMinutes: delay.clamp(0, 1440),
      notes: notesController.text.trim(),
    );
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _deleteEvent(int index) async {
    final event = widget.route.events[index];
    final confirmed = await _confirm('Delete event?', '${event.type.label} at ${_time(event.timestamp)} will be removed.');
    if (!confirmed) return;
    widget.route.events.removeAt(index);
    await _save();
    if (mounted) setState(() {});
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correct route activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Checkpoints', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (widget.route.checkpoints.isEmpty) const Text('No checkpoints recorded.'),
          ...List.generate(widget.route.checkpoints.length, (index) {
            final checkpoint = widget.route.checkpoints[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Stop ${checkpoint.stopNumber}'),
                subtitle: Text(_time(checkpoint.timestamp)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editCheckpoint(index);
                    if (value == 'delete') _deleteCheckpoint(index);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text('Events', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (widget.route.events.isEmpty) const Text('No events recorded.'),
          ...List.generate(widget.route.events.length, (index) {
            final event = widget.route.events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(event.type.label),
                subtitle: Text([
                  _time(event.timestamp),
                  if (event.stopNumber != null) 'Stop ${event.stopNumber}',
                  if (event.delayMinutes > 0) '${event.delayMinutes} min delay',
                  if (event.notes.isNotEmpty) event.notes,
                ].join(' • ')),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editEvent(index);
                    if (value == 'delete') _deleteEvent(index);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
