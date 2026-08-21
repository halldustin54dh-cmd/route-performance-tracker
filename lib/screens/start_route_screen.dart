import 'package:flutter/material.dart';
import '../models/delivery_route.dart';
import '../services/route_repository.dart';
import 'live_route_screen.dart';

class StartRouteScreen extends StatefulWidget {
  const StartRouteScreen({super.key, required this.repository});
  final RouteRepository repository;

  @override
  State<StartRouteScreen> createState() => _StartRouteScreenState();
}

class _StartRouteScreenState extends State<StartRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stops = TextEditingController();
  final _locations = TextEditingController();
  final _packages = TextEditingController();
  final _apartments = TextEditingController();
  final _businesses = TextEditingController();
  final _rural = TextEditingController();
  final _multi = TextEditingController();
  final _drive = TextEditingController();
  String _routeType = 'Mixed';
  int _weather = 0;
  int _access = 0;
  int _spread = 0;
  bool _saving = false;
  bool _showDifficulty = false;

  @override
  void dispose() {
    for (final controller in [_stops, _locations, _packages, _apartments, _businesses, _rural, _multi, _drive]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _intOrZero(String value) => int.tryParse(value.trim()) ?? 0;
  double _doubleOrZero(String value) => double.tryParse(value.trim()) ?? 0;

  Future<void> _saveSetup() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final historicalPace = await widget.repository.adjustedPaceBaseline(date);
    final route = DeliveryRoute(
      date: date,
      startingStops: int.parse(_stops.text.trim()),
      startingLocations: _intOrZero(_locations.text),
      startingPackages: _intOrZero(_packages.text),
      routeType: _routeType,
      historicalAdjustedPace: historicalPace,
      apartmentStops: _intOrZero(_apartments.text),
      businessStops: _intOrZero(_businesses.text),
      ruralStops: _intOrZero(_rural.text),
      multiLocationStops: _intOrZero(_multi.text),
      averageDriveMinutes: _doubleOrZero(_drive.text),
      weatherSeverity: _weather,
      accessDifficulty: _access,
      routeSpread: _spread,
    );
    await widget.repository.createRoute(route);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LiveRouteScreen(route: route, repository: widget.repository)),
    );
  }

  Widget _scoreDropdown(String label, int value, ValueChanged<int> onChanged) => DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: List.generate(6, (index) => DropdownMenuItem(value: index, child: Text('$index'))),
        onChanged: (next) => onChanged(next ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Route Setup')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Set up today’s route', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Enter what you know at loadout. This does not start the delivery clock.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _stops,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Starting stops *'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        return parsed == null || parsed <= 0 ? 'Enter a valid stop count' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _locations, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Locations'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _packages, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Packages'))),
                    ]),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _routeType,
                      decoration: const InputDecoration(labelText: 'Route type'),
                      items: const ['Residential','Mixed','Rural','Downtown / Urban','Apartment-heavy','Business-heavy','Custom']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setState(() => _routeType = value ?? 'Mixed'),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(children: [
                        ListTile(
                          leading: const Icon(Icons.query_stats_outlined),
                          title: const Text('Route difficulty inputs'),
                          subtitle: const Text('Optional. Add what you know for a transparent difficulty score.'),
                          trailing: Icon(_showDifficulty ? Icons.expand_less : Icons.expand_more),
                          onTap: () => setState(() => _showDifficulty = !_showDifficulty),
                        ),
                        if (_showDifficulty) Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(children: [
                            Row(children: [
                              Expanded(child: TextFormField(controller: _apartments, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Apartment stops'))),
                              const SizedBox(width: 10),
                              Expanded(child: TextFormField(controller: _businesses, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Business stops'))),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: TextFormField(controller: _rural, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rural stops'))),
                              const SizedBox(width: 10),
                              Expanded(child: TextFormField(controller: _multi, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Multi-location stops'))),
                            ]),
                            const SizedBox(height: 10),
                            TextFormField(controller: _drive, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Avg drive minutes / stop')),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _scoreDropdown('Weather 0–5', _weather, (v) => setState(() => _weather = v))),
                              const SizedBox(width: 10),
                              Expanded(child: _scoreDropdown('Access 0–5', _access, (v) => setState(() => _access = v))),
                            ]),
                            const SizedBox(height: 10),
                            _scoreDropdown('Route spread 0–5', _spread, (v) => setState(() => _spread = v)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveSetup,
                      icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save Route Setup')),
                    ),
                    const SizedBox(height: 12),
                    Text('Your 30-day adjusted pace is pulled from local route history automatically when available.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
