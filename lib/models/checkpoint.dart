class Checkpoint {
  const Checkpoint({
    this.id,
    required this.stopNumber,
    required this.timestamp,
  });

  final int? id;
  final int stopNumber;
  final DateTime timestamp;

  Map<String, Object?> toDbMap(int routeId) => {
        'route_id': routeId,
        'stop_number': stopNumber,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Checkpoint.fromDbMap(Map<String, Object?> map) => Checkpoint(
        id: map['id'] as int?,
        stopNumber: map['stop_number'] as int,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
