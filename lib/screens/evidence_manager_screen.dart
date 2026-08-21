import 'dart:io';

import 'package:flutter/material.dart';

import '../models/delivery_route.dart';
import '../models/route_evidence.dart';
import '../services/route_repository.dart';

class EvidenceManagerScreen extends StatefulWidget {
  const EvidenceManagerScreen({
    super.key,
    required this.route,
    required this.repository,
  });

  final DeliveryRoute route;
  final RouteRepository repository;

  @override
  State<EvidenceManagerScreen> createState() => _EvidenceManagerScreenState();
}

class _EvidenceManagerScreenState extends State<EvidenceManagerScreen> {
  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _edit(int index) async {
    final current = widget.route.evidence[index];
    var type = current.type;
    final caption = TextEditingController(text: current.caption);
    final stop = TextEditingController(text: current.stopNumber?.toString() ?? '');

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit evidence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<EvidenceType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Evidence type'),
                  items: EvidenceType.values
                      .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stop,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stop number (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caption,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Caption'),
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
    final stopNumber = stop.text.trim().isEmpty ? null : int.tryParse(stop.text.trim());
    widget.route.evidence[index] = RouteEvidence(
      id: current.id,
      filePath: current.filePath,
      timestamp: current.timestamp,
      type: type,
      stopNumber: stopNumber,
      caption: caption.text.trim(),
      relatedEventType: current.relatedEventType,
    );
    await widget.repository.saveRoute(widget.route);
    if (mounted) setState(() {});
  }

  Future<void> _delete(int index) async {
    final current = widget.route.evidence[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete evidence?'),
        content: const Text('This removes the evidence entry and its locally stored image file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    widget.route.evidence.removeAt(index);
    await widget.repository.saveRoute(widget.route);
    final file = File(current.filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Database deletion is more important than failing to remove an orphaned local file.
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Manager')),
      body: widget.route.evidence.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No evidence captured for this route.')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.route.evidence.length,
              itemBuilder: (context, index) {
                final item = widget.route.evidence[index];
                final file = File(item.filePath);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (file.existsSync())
                        Image.file(file, height: 180, fit: BoxFit.cover)
                      else
                        const SizedBox(
                          height: 140,
                          child: Center(child: Icon(Icons.image_not_supported_outlined, size: 42)),
                        ),
                      ListTile(
                        title: Text(item.type.label),
                        subtitle: Text([
                          _time(item.timestamp),
                          if (item.stopNumber != null) 'Stop ${item.stopNumber}',
                          item.suggestedFileName,
                          if (item.caption.isNotEmpty) item.caption,
                        ].join(' • ')),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _edit(index);
                            if (value == 'delete') _delete(index);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit details')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
