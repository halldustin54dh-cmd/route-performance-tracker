import 'package:sqflite/sqflite.dart';
import '../models/checkpoint.dart';
import '../models/delivery_route.dart';
import '../models/route_event.dart';
import '../models/route_evidence.dart';
import 'route_metrics_service.dart';

class RouteRepository {
  RouteRepository._();

  static final RouteRepository instance = RouteRepository._();
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final root = await getDatabasesPath();
    _db = await openDatabase(
      '$root/route_performance_tracker.db',
      version: 2,
      onCreate: (db, version) async => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final statement in [
            'ALTER TABLE routes ADD COLUMN apartment_stops INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN business_stops INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN rural_stops INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN multi_location_stops INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN average_drive_minutes REAL NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN weather_severity INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN access_difficulty INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE routes ADD COLUMN route_spread INTEGER NOT NULL DEFAULT 0',
          ]) {
            await db.execute(statement);
          }
          await db.execute('''
            CREATE TABLE route_evidence(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              route_id INTEGER NOT NULL,
              file_path TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              type TEXT NOT NULL,
              stop_number INTEGER,
              caption TEXT NOT NULL DEFAULT '',
              related_event_type TEXT,
              FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('CREATE INDEX idx_evidence_route ON route_evidence(route_id)');
        }
      },
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE routes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        starting_stops INTEGER NOT NULL,
        starting_locations INTEGER NOT NULL DEFAULT 0,
        starting_packages INTEGER NOT NULL DEFAULT 0,
        first_stop_time TEXT,
        final_stop_time TEXT,
        route_type TEXT NOT NULL,
        historical_adjusted_pace REAL,
        apartment_stops INTEGER NOT NULL DEFAULT 0,
        business_stops INTEGER NOT NULL DEFAULT 0,
        rural_stops INTEGER NOT NULL DEFAULT 0,
        multi_location_stops INTEGER NOT NULL DEFAULT 0,
        average_drive_minutes REAL NOT NULL DEFAULT 0,
        weather_severity INTEGER NOT NULL DEFAULT 0,
        access_difficulty INTEGER NOT NULL DEFAULT 0,
        route_spread INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE checkpoints(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        stop_number INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE route_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        stop_number INTEGER,
        delay_minutes INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE route_evidence(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        stop_number INTEGER,
        caption TEXT NOT NULL DEFAULT '',
        related_event_type TEXT,
        FOREIGN KEY(route_id) REFERENCES routes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_routes_date ON routes(date)');
    await db.execute('CREATE INDEX idx_checkpoints_route ON checkpoints(route_id)');
    await db.execute('CREATE INDEX idx_events_route ON route_events(route_id)');
    await db.execute('CREATE INDEX idx_evidence_route ON route_evidence(route_id)');
  }

  Database get db {
    final value = _db;
    if (value == null) throw StateError('RouteRepository.init() must be called first.');
    return value;
  }

  Future<DeliveryRoute> createRoute(DeliveryRoute route) async {
    final id = await db.insert('routes', route.toDbMap());
    route.id = id;
    return route;
  }

  Future<void> saveRoute(DeliveryRoute route) async {
    final routeId = route.id;
    if (routeId == null) throw StateError('Cannot save a route without an id.');

    await db.transaction((txn) async {
      await txn.update('routes', route.toDbMap(), where: 'id = ?', whereArgs: [routeId]);
      await txn.delete('checkpoints', where: 'route_id = ?', whereArgs: [routeId]);
      await txn.delete('route_events', where: 'route_id = ?', whereArgs: [routeId]);
      await txn.delete('route_evidence', where: 'route_id = ?', whereArgs: [routeId]);

      for (final checkpoint in route.checkpoints) {
        await txn.insert('checkpoints', checkpoint.toDbMap(routeId));
      }
      for (final event in route.events) {
        await txn.insert('route_events', event.toDbMap(routeId));
      }
      for (final item in route.evidence) {
        await txn.insert('route_evidence', item.toDbMap(routeId));
      }
    });
  }

  Future<int> restoreCloudRoutes(List<Map<String, dynamic>> cloudRows) async {
    var restored = 0;
    for (final cloudRow in cloudRows) {
      final rawPayload = cloudRow['payload'];
      if (rawPayload is! Map) continue;
      final payload = Map<String, dynamic>.from(rawPayload);
      if ((payload['schema_version'] as num?)?.toInt() != 1) continue;

      final dateText = payload['date'] as String?;
      final firstStopText = payload['first_stop_time'] as String?;
      final startingStops = (payload['starting_stops'] as num?)?.toInt();
      final startingPackages = (payload['starting_packages'] as num?)?.toInt() ?? 0;
      if (dateText == null || startingStops == null || startingStops <= 0) continue;

      final existing = await db.query(
        'routes',
        where: 'date = ? AND starting_stops = ? AND starting_packages = ? AND COALESCE(first_stop_time, "") = ?',
        whereArgs: [DateTime.parse(dateText).toLocal().toIso8601String(), startingStops, startingPackages, firstStopText == null ? '' : DateTime.parse(firstStopText).toLocal().toIso8601String()],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      final route = DeliveryRoute(
        date: DateTime.parse(dateText).toLocal(),
        startingStops: startingStops,
        startingLocations: (payload['starting_locations'] as num?)?.toInt() ?? 0,
        startingPackages: startingPackages,
        firstStopTime: firstStopText == null ? null : DateTime.parse(firstStopText).toLocal(),
        finalStopTime: payload['final_stop_time'] == null ? null : DateTime.parse(payload['final_stop_time'] as String).toLocal(),
        routeType: payload['route_type'] as String? ?? 'Mixed',
        historicalAdjustedPace: (payload['historical_adjusted_pace'] as num?)?.toDouble(),
        apartmentStops: (payload['apartment_stops'] as num?)?.toInt() ?? 0,
        businessStops: (payload['business_stops'] as num?)?.toInt() ?? 0,
        ruralStops: (payload['rural_stops'] as num?)?.toInt() ?? 0,
        multiLocationStops: (payload['multi_location_stops'] as num?)?.toInt() ?? 0,
        averageDriveMinutes: (payload['average_drive_minutes'] as num?)?.toDouble() ?? 0,
        weatherSeverity: (payload['weather_severity'] as num?)?.toInt() ?? 0,
        accessDifficulty: (payload['access_difficulty'] as num?)?.toInt() ?? 0,
        routeSpread: (payload['route_spread'] as num?)?.toInt() ?? 0,
        checkpoints: ((payload['checkpoints'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['stop_number'] is num && item['timestamp'] is String)
            .map((item) => Checkpoint(
                  stopNumber: (item['stop_number'] as num).toInt(),
                  timestamp: DateTime.parse(item['timestamp'] as String).toLocal(),
                ))
            .toList(),
        events: ((payload['events'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['type'] is String && item['timestamp'] is String)
            .map((item) => RouteEvent(
                  type: RouteEventType.fromName(item['type'] as String),
                  timestamp: DateTime.parse(item['timestamp'] as String).toLocal(),
                  stopNumber: (item['stop_number'] as num?)?.toInt(),
                  delayMinutes: (item['delay_minutes'] as num?)?.toInt() ?? 0,
                  notes: item['notes'] as String? ?? '',
                ))
            .toList(),
      );

      await createRoute(route);
      await saveRoute(route);
      restored += 1;
    }
    return restored;
  }

  Future<DeliveryRoute?> activeRoute() async {
    final rows = await db.query('routes', where: 'final_stop_time IS NULL', orderBy: 'date DESC, id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<List<DeliveryRoute>> completedRoutes() async {
    final rows = await db.query('routes', where: 'final_stop_time IS NOT NULL', orderBy: 'date DESC, id DESC');
    final result = <DeliveryRoute>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  Future<List<DeliveryRoute>> allRoutes() async {
    final rows = await db.query('routes', orderBy: 'date DESC, id DESC');
    final result = <DeliveryRoute>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  Future<double?> adjustedPaceBaseline(DateTime beforeDate) async {
    final start = beforeDate.subtract(const Duration(days: 30));
    final rows = await db.query(
      'routes',
      where: 'final_stop_time IS NOT NULL AND date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), beforeDate.toIso8601String()],
      orderBy: 'date DESC',
    );

    const metrics = RouteMetricsService();
    final values = <double>[];
    for (final row in rows) {
      final route = await _hydrate(row);
      final pace = metrics.adjustedPace(route);
      if (pace != null && pace > 0) values.add(pace);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> deleteRoute(int routeId) async {
    await db.delete('routes', where: 'id = ?', whereArgs: [routeId]);
  }

  Future<DeliveryRoute> _hydrate(Map<String, Object?> routeRow) async {
    final routeId = routeRow['id'] as int;
    final checkpointRows = await db.query('checkpoints', where: 'route_id = ?', whereArgs: [routeId], orderBy: 'timestamp ASC, id ASC');
    final eventRows = await db.query('route_events', where: 'route_id = ?', whereArgs: [routeId], orderBy: 'timestamp ASC, id ASC');
    final evidenceRows = await db.query('route_evidence', where: 'route_id = ?', whereArgs: [routeId], orderBy: 'timestamp ASC, id ASC');
    return DeliveryRoute.fromDbMap(
      routeRow,
      checkpoints: checkpointRows.map(Checkpoint.fromDbMap).toList(),
      events: eventRows.map(RouteEvent.fromDbMap).toList(),
      evidence: evidenceRows.map(RouteEvidence.fromDbMap).toList(),
    );
  }
}
