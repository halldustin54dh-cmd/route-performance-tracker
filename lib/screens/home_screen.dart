import 'package:flutter/material.dart';
import '../models/delivery_route.dart';
import '../services/route_metrics_service.dart';
import '../services/route_repository.dart';
import 'history_detail_screen.dart';
import 'live_route_screen.dart';
import 'start_route_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final RouteRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _metrics = const RouteMetricsService();
  int _tab = 0;
  DeliveryRoute? _active;
  List<DeliveryRoute> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final active = await widget.repository.activeRoute();
    final history = await widget.repository.completedRoutes();
    if (!mounted) return;
    setState(() {
      _active = active;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _openSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StartRouteScreen(repository: widget.repository)),
    );
    await _reload();
  }

  Future<void> _resume() async {
    final route = _active;
    if (route == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveRouteScreen(route: route, repository: widget.repository)),
    );
    await _reload();
  }

  String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
  String _pace(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)}/hr';

  String _duration(DeliveryRoute route) {
    final value = _metrics.routeDuration(route);
    if (value == null) return '—';
    final hours = value.inMinutes ~/ 60;
    final minutes = value.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Route Performance Tracker')),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _todayTab(context),
            _historyTab(context),
            AnalyticsScreen(routes: _history),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Analytics'),
        ],
      ),
    );
  }

  Widget _todayTab(BuildContext context) {
    final theme = Theme.of(context);
    final route = _active;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Today', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          route == null ? 'No active route.' : (route.hasStarted ? 'Your route is in progress and safely stored on this device.' : 'Route setup saved. Delivery timing has not started yet.'),
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        if (route == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.add_road_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text('Ready for a route?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  const Text('Enter the route counts now. Start the delivery clock later at the actual first stop.', textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton.icon(onPressed: _openSetup, icon: const Icon(Icons.add), label: const Text('Set Up Route')),
                ],
              ),
            ),
          )
        else
          Card(
            color: const Color(0xFF172033),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.hasStarted ? 'Route in progress' : 'Route ready', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${route.startingStops} stops • ${route.routeType}', style: const TextStyle(color: Colors.white70)),
                  if (route.hasStarted) ...[
                    const SizedBox(height: 4),
                    Text('Stop ${route.currentStop} • ${route.stopsRemaining} remaining', style: const TextStyle(color: Colors.white70)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _resume,
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF172033)),
                    icon: Icon(route.hasStarted ? Icons.play_arrow_rounded : Icons.flag_outlined),
                    label: Text(route.hasStarted ? 'Resume Route' : 'Open Route'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (_history.isNotEmpty) ...[
          Text('Recent', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._history.take(3).map(_historyCard),
        ],
      ],
    );
  }

  Widget _historyTab(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Route History', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${_history.length} completed routes stored locally', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (_history.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Completed routes will appear here.')))
          else
            ..._history.map(_historyCard),
        ],
      ),
    );
  }

  Widget _historyCard(DeliveryRoute route) {
    final adjusted = _metrics.adjustedPace(route);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.check_rounded)),
        title: Text('${_date(route.date)} • ${route.startingStops} stops'),
        subtitle: Text('${route.routeType} • ${_duration(route)} • ${_pace(adjusted)} adjusted'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HistoryDetailScreen(route: route)),
        ),
      ),
    );
  }
}
