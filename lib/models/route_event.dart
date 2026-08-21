enum RouteEventType {
  bathroom('Bathroom'),
  lunch('Lunch'),
  badGps('Bad GPS'),
  wrongAddress('Wrong Address'),
  apartmentAccess('Apartment / Access'),
  traffic('Traffic'),
  construction('Construction'),
  rescueReceived('Rescue Received'),
  rescueGiven('Rescue Given'),
  dispatchCall('Dispatch Call'),
  vehicleProblem('Vehicle Problem'),
  heatCooling('Heat / Cooling'),
  custom('Custom');

  const RouteEventType(this.label);
  final String label;

  static RouteEventType fromName(String value) => RouteEventType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => RouteEventType.custom,
      );
}

class RouteEvent {
  const RouteEvent({
    this.id,
    required this.type,
    required this.timestamp,
    this.stopNumber,
    this.delayMinutes = 0,
    this.notes = '',
  });

  final int? id;
  final RouteEventType type;
  final DateTime timestamp;
  final int? stopNumber;
  final int delayMinutes;
  final String notes;

  Map<String, Object?> toDbMap(int routeId) => {
        'route_id': routeId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'stop_number': stopNumber,
        'delay_minutes': delayMinutes,
        'notes': notes,
      };

  factory RouteEvent.fromDbMap(Map<String, Object?> map) => RouteEvent(
        id: map['id'] as int?,
        type: RouteEventType.fromName(map['type'] as String),
        timestamp: DateTime.parse(map['timestamp'] as String),
        stopNumber: map['stop_number'] as int?,
        delayMinutes: (map['delay_minutes'] as int?) ?? 0,
        notes: (map['notes'] as String?) ?? '',
      );
}
