enum EvidenceType {
  routeDocumentation('Route Documentation'),
  incidentEvidence('Incident Evidence'),
  vehicleSafety('Vehicle / Safety Evidence'),
  other('Other');

  const EvidenceType(this.label);
  final String label;

  static EvidenceType fromName(String value) => EvidenceType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => EvidenceType.other,
      );
}

class RouteEvidence {
  const RouteEvidence({
    this.id,
    required this.filePath,
    required this.timestamp,
    required this.type,
    this.stopNumber,
    this.caption = '',
    this.relatedEventType,
  });

  final int? id;
  final String filePath;
  final DateTime timestamp;
  final EvidenceType type;
  final int? stopNumber;
  final String caption;
  final String? relatedEventType;

  String get suggestedFileName {
    final date = '${timestamp.year.toString().padLeft(4, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final stop = (stopNumber ?? 0).toString().padLeft(3, '0');
    final label = (relatedEventType?.isNotEmpty == true ? relatedEventType! : type.label)
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
    return '${date}_Stop${stop}_$label';
  }

  Map<String, Object?> toDbMap(int routeId) => {
        'route_id': routeId,
        'file_path': filePath,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'stop_number': stopNumber,
        'caption': caption,
        'related_event_type': relatedEventType,
      };

  factory RouteEvidence.fromDbMap(Map<String, Object?> map) => RouteEvidence(
        id: map['id'] as int?,
        filePath: map['file_path'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        type: EvidenceType.fromName(map['type'] as String),
        stopNumber: map['stop_number'] as int?,
        caption: (map['caption'] as String?) ?? '',
        relatedEventType: map['related_event_type'] as String?,
      );
}
