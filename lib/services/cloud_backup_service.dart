import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_route.dart';
import 'account_service.dart';
import 'entitlement_service.dart';

class CloudBackupService {
  const CloudBackupService();

  Future<void> _requirePro() async {
    final accounts = AccountService.instance;
    if (!accounts.isInitialized || accounts.currentUser == null) {
      throw StateError('Sign in to use cloud backup and restore.');
    }
    final entitlement = await const EntitlementService().current();
    if (!entitlement.isPro) {
      throw StateError('Cloud backup and restore are Pro features.');
    }
  }

  Future<int> backupCompletedRoutes(List<DeliveryRoute> routes) async {
    await _requirePro();
    final user = AccountService.instance.currentUser!;
    final completed = routes.where((route) => route.isComplete).toList(growable: false);
    if (completed.isEmpty) return 0;

    final client = Supabase.instance.client;
    for (final route in completed) {
      final cloudId = _cloudId(user.id, route);
      await client.from('routes').upsert({
        'id': cloudId,
        'user_id': user.id,
        'route_date': route.date.toUtc().toIso8601String(),
        'payload': _payload(route),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    return completed.length;
  }

  Future<List<Map<String, dynamic>>> loadCloudRoutes() async {
    await _requirePro();
    final rows = await Supabase.instance.client
        .from('routes')
        .select('id,route_date,payload,updated_at')
        .order('route_date', ascending: true);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  String _cloudId(String userId, DeliveryRoute route) {
    final first = route.firstStopTime?.toUtc().toIso8601String() ?? 'not-started';
    final raw = '$userId|${route.date.toUtc().toIso8601String()}|$first|${route.startingStops}|${route.startingPackages}';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Map<String, Object?> _payload(DeliveryRoute route) => {
        'schema_version': 1,
        'date': route.date.toUtc().toIso8601String(),
        'starting_stops': route.startingStops,
        'starting_locations': route.startingLocations,
        'starting_packages': route.startingPackages,
        'first_stop_time': route.firstStopTime?.toUtc().toIso8601String(),
        'final_stop_time': route.finalStopTime?.toUtc().toIso8601String(),
        'route_type': route.routeType,
        'historical_adjusted_pace': route.historicalAdjustedPace,
        'apartment_stops': route.apartmentStops,
        'business_stops': route.businessStops,
        'rural_stops': route.ruralStops,
        'multi_location_stops': route.multiLocationStops,
        'average_drive_minutes': route.averageDriveMinutes,
        'weather_severity': route.weatherSeverity,
        'access_difficulty': route.accessDifficulty,
        'route_spread': route.routeSpread,
        'checkpoints': route.checkpoints
            .map((checkpoint) => {'stop_number': checkpoint.stopNumber, 'timestamp': checkpoint.timestamp.toUtc().toIso8601String()})
            .toList(growable: false),
        'events': route.events
            .map((event) => {
                  'type': event.type.name,
                  'timestamp': event.timestamp.toUtc().toIso8601String(),
                  'stop_number': event.stopNumber,
                  'delay_minutes': event.delayMinutes,
                  'notes': event.notes,
                })
            .toList(growable: false),
        'evidence_metadata': route.evidence
            .map((evidence) => {
                  'timestamp': evidence.timestamp.toUtc().toIso8601String(),
                  'type': evidence.type.name,
                  'stop_number': evidence.stopNumber,
                  'caption': evidence.caption,
                  'related_event_type': evidence.relatedEventType,
                  'suggested_file_name': evidence.suggestedFileName,
                })
            .toList(growable: false),
      };
}
