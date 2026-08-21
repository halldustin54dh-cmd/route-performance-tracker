import 'checkpoint.dart';
import 'route_event.dart';
import 'route_evidence.dart';

class DeliveryRoute {
  DeliveryRoute({
    this.id,
    required this.date,
    required this.startingStops,
    required this.startingLocations,
    required this.startingPackages,
    this.firstStopTime,
    this.finalStopTime,
    this.routeType = 'Mixed',
    this.historicalAdjustedPace,
    this.apartmentStops = 0,
    this.businessStops = 0,
    this.ruralStops = 0,
    this.multiLocationStops = 0,
    this.averageDriveMinutes = 0,
    this.weatherSeverity = 0,
    this.accessDifficulty = 0,
    this.routeSpread = 0,
    List<Checkpoint>? checkpoints,
    List<RouteEvent>? events,
    List<RouteEvidence>? evidence,
  })  : checkpoints = checkpoints ?? [],
        events = events ?? [],
        evidence = evidence ?? [];

  int? id;
  final DateTime date;
  final int startingStops;
  final int startingLocations;
  final int startingPackages;
  DateTime? firstStopTime;
  DateTime? finalStopTime;
  final String routeType;
  final double? historicalAdjustedPace;

  final int apartmentStops;
  final int businessStops;
  final int ruralStops;
  final int multiLocationStops;
  final double averageDriveMinutes;
  final int weatherSeverity;
  final int accessDifficulty;
  final int routeSpread;

  final List<Checkpoint> checkpoints;
  final List<RouteEvent> events;
  final List<RouteEvidence> evidence;

  bool get hasStarted => firstStopTime != null;
  int get currentStop => checkpoints.isEmpty ? 0 : checkpoints.last.stopNumber;
  int get stopsRemaining => (startingStops - currentStop).clamp(0, startingStops).toInt();
  int get documentedDelayMinutes => events.fold(0, (sum, event) => sum + event.delayMinutes);
  bool get isComplete => finalStopTime != null;

  double? get locationsPerStop => startingStops > 0 && startingLocations > 0 ? startingLocations / startingStops : null;
  double? get packagesPerStop => startingStops > 0 && startingPackages > 0 ? startingPackages / startingStops : null;

  Map<String, Object?> toDbMap() => {
        'date': date.toIso8601String(),
        'starting_stops': startingStops,
        'starting_locations': startingLocations,
        'starting_packages': startingPackages,
        'first_stop_time': firstStopTime?.toIso8601String(),
        'final_stop_time': finalStopTime?.toIso8601String(),
        'route_type': routeType,
        'historical_adjusted_pace': historicalAdjustedPace,
        'apartment_stops': apartmentStops,
        'business_stops': businessStops,
        'rural_stops': ruralStops,
        'multi_location_stops': multiLocationStops,
        'average_drive_minutes': averageDriveMinutes,
        'weather_severity': weatherSeverity,
        'access_difficulty': accessDifficulty,
        'route_spread': routeSpread,
      };

  factory DeliveryRoute.fromDbMap(
    Map<String, Object?> map, {
    List<Checkpoint>? checkpoints,
    List<RouteEvent>? events,
    List<RouteEvidence>? evidence,
  }) =>
      DeliveryRoute(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        startingStops: map['starting_stops'] as int,
        startingLocations: (map['starting_locations'] as int?) ?? 0,
        startingPackages: (map['starting_packages'] as int?) ?? 0,
        firstStopTime: map['first_stop_time'] == null ? null : DateTime.parse(map['first_stop_time'] as String),
        finalStopTime: map['final_stop_time'] == null ? null : DateTime.parse(map['final_stop_time'] as String),
        routeType: (map['route_type'] as String?) ?? 'Mixed',
        historicalAdjustedPace: (map['historical_adjusted_pace'] as num?)?.toDouble(),
        apartmentStops: (map['apartment_stops'] as int?) ?? 0,
        businessStops: (map['business_stops'] as int?) ?? 0,
        ruralStops: (map['rural_stops'] as int?) ?? 0,
        multiLocationStops: (map['multi_location_stops'] as int?) ?? 0,
        averageDriveMinutes: (map['average_drive_minutes'] as num?)?.toDouble() ?? 0,
        weatherSeverity: (map['weather_severity'] as int?) ?? 0,
        accessDifficulty: (map['access_difficulty'] as int?) ?? 0,
        routeSpread: (map['route_spread'] as int?) ?? 0,
        checkpoints: checkpoints,
        events: events,
        evidence: evidence,
      );
}
