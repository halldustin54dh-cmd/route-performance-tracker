import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/delivery_route.dart';
import '../models/route_evidence.dart';
import '../models/route_screenshot_analysis.dart';
import '../models/route_vision_analysis.dart';
import '../services/evidence_storage_service.dart';
import '../services/route_repository.dart';
import '../services/route_screenshot_analysis_service.dart';
import '../services/route_vision_service.dart';
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
  final _picker = ImagePicker();
  final _screenshotAnalysis = const RouteScreenshotAnalysisService();
  final _vision = const RouteVisionService();
  final _evidenceStorage = const EvidenceStorageService();

  String _routeType = 'Mixed';
  int _weather = 0;
  int _access = 0;
  int _spread = 0;
  bool _saving = false;
  bool _analyzing = false;
  bool _showDifficulty = false;
  List<XFile> _importedScreenshots = const [];
  RouteScreenshotBatchAnalysis? _analysisResult;
  RouteVisionAnalysis? _visionResult;

  @override
  void dispose() {
    for (final controller in [_stops, _locations, _packages, _apartments, _businesses, _rural, _multi, _drive]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _intOrZero(String value) => int.tryParse(value.trim()) ?? 0;
  double _doubleOrZero(String value) => double.tryParse(value.trim()) ?? 0;

  void _applyAnalysis(RouteScreenshotBatchAnalysis analysis, RouteVisionAnalysis? vision) {
    if (analysis.stops != null) _stops.text = '${analysis.stops}';
    if (analysis.locations != null) _locations.text = '${analysis.locations}';
    if (analysis.packages != null) _packages.text = '${analysis.packages}';
    if (analysis.multiLocationStops != null) _multi.text = '${analysis.multiLocationStops}';
    if (vision != null) {
      _spread = vision.routeSpread.clamp(0, 5);
      _access = vision.accessComplexity.clamp(0, 5);
      if (vision.estimatedAverageDriveMinutes != null) {
        _drive.text = vision.estimatedAverageDriveMinutes!.toStringAsFixed(1);
      }
      _routeType = _normalizeRouteType(vision.likelyRouteType);
      _showDifficulty = true;
    }
  }

  String _normalizeRouteType(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('rural')) return 'Rural';
    if (lower.contains('downtown') || lower.contains('urban')) return 'Downtown / Urban';
    if (lower.contains('apartment')) return 'Apartment-heavy';
    if (lower.contains('business')) return 'Business-heavy';
    if (lower.contains('residential')) return 'Residential';
    return 'Mixed';
  }

  Future<bool> _reviewAnalysis(RouteScreenshotBatchAnalysis analysis, RouteVisionAnalysis? vision) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route screenshots analyzed'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${analysis.items.length} image${analysis.items.length == 1 ? '' : 's'} analyzed with on-device OCR.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (analysis.stops != null) Chip(label: Text('${analysis.stops} stops')),
                    if (analysis.locations != null) Chip(label: Text('${analysis.locations} locations')),
                    if (analysis.packages != null) Chip(label: Text('${analysis.packages} packages')),
                    if (analysis.multiLocationStops != null) Chip(label: Text('${analysis.multiLocationStops} multi-location')),
                  ],
                ),
                if (vision != null) ...[
                  const SizedBox(height: 18),
                  Row(children: [
                    const Icon(Icons.auto_awesome_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Secure map vision', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 8),
                  Text(vision.summary.isEmpty ? 'Map geometry was analyzed by the secure backend.' : vision.summary),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Spread ${vision.routeSpread}/5')),
                      Chip(label: Text('Rurality ${vision.rurality}/5')),
                      Chip(label: Text('Clustering ${vision.clustering}/5')),
                      Chip(label: Text('Backtracking ${vision.backtrackingRisk}/5')),
                      Chip(label: Text('Access ${vision.accessComplexity}/5')),
                      Chip(label: Text('${(vision.confidence * 100).round()}% confidence')),
                    ],
                  ),
                  if (vision.signals.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...vision.signals.map((signal) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('• '),
                            Expanded(child: Text(signal)),
                          ]),
                        )),
                  ],
                ] else ...[
                  const SizedBox(height: 14),
                  Text(
                    _vision.isConfigured
                        ? 'Secure map vision was unavailable for this import. OCR results are still usable.'
                        : 'This build has no secure vision backend configured, so only on-device OCR ran.',
                  ),
                ],
                const SizedBox(height: 16),
                ...analysis.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final percent = (item.confidence * 100).round();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: Text('Image ${entry.key + 1}: ${item.kind.label}'),
                      subtitle: Text([
                        '$percent% classification confidence',
                        if (item.routeCode != null) 'Route ${item.routeCode}',
                        if (item.notes.isNotEmpty) item.notes.join(' '),
                      ].join('\n')),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text('Review populated fields before saving. OCR and vision scores are evidence-based estimates, not facts pulled from Amazon.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply to Route Setup')),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _importRouteScreenshots() async {
    if (_analyzing) return;
    final picked = await _picker.pickMultiImage(imageQuality: 90, limit: 12);
    if (picked.isEmpty || !mounted) return;

    setState(() => _analyzing = true);
    try {
      final analysis = await _screenshotAnalysis.analyze(picked.map((item) => item.path).toList());
      RouteVisionAnalysis? vision;
      if (_vision.isConfigured) {
        try {
          final ocrText = analysis.items.map((item) => item.rawText).where((text) => text.trim().isNotEmpty).join('\n\n--- screenshot ---\n\n');
          final preferred = analysis.items
              .where((item) => item.kind == RouteScreenshotKind.routeMap)
              .map((item) => item.filePath)
              .toList();
          final paths = preferred.isNotEmpty ? preferred : picked.map((item) => item.path).toList();
          vision = await _vision.analyze(imagePaths: paths.take(6).toList(), ocrText: ocrText);
        } catch (_) {
          vision = null;
        }
      }
      if (!mounted) return;
      final apply = await _reviewAnalysis(analysis, vision);
      if (!apply || !mounted) return;
      setState(() {
        _importedScreenshots = picked;
        _analysisResult = analysis;
        _visionResult = vision;
        _applyAnalysis(analysis, vision);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not analyze screenshots: $error')));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _saveImportedScreenshots(DeliveryRoute route) async {
    if (_importedScreenshots.isEmpty) return;
    final analysis = _analysisResult;
    final now = DateTime.now();
    for (var index = 0; index < _importedScreenshots.length; index++) {
      final picked = _importedScreenshots[index];
      final item = analysis != null && index < analysis.items.length ? analysis.items[index] : null;
      final kind = item?.kind.label ?? 'Route screenshot';
      final visionSuffix = _visionResult == null || index != 0 ? '' : ' • Vision spread ${_visionResult!.routeSpread}/5';
      final draft = RouteEvidence(
        filePath: picked.path,
        timestamp: now.add(Duration(milliseconds: index)),
        type: EvidenceType.routeDocumentation,
        caption: 'Imported $kind${item?.routeCode == null ? '' : ' • Route ${item!.routeCode}'}$visionSuffix',
      );
      final storedPath = await _evidenceStorage.persistImage(
        sourcePath: picked.path,
        suggestedBaseName: '${draft.suggestedFileName}_${index + 1}_${kind.replaceAll(' ', '')}',
      );
      route.evidence.add(RouteEvidence(
        filePath: storedPath,
        timestamp: draft.timestamp,
        type: draft.type,
        caption: draft.caption,
      ));
    }
    await widget.repository.saveRoute(route);
  }

  Future<void> _saveSetup() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
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
      await _saveImportedScreenshots(route);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LiveRouteScreen(route: route, repository: widget.repository)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                    Text('Import route screenshots or enter what you know at loadout. This does not start the delivery clock.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 18),
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Icon(Icons.document_scanner_outlined, color: theme.colorScheme.onSecondaryContainer),
                              const SizedBox(width: 10),
                              Expanded(child: Text('Import route screenshots', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                            ]),
                            const SizedBox(height: 6),
                            Text(_vision.isConfigured
                                ? 'On-device OCR extracts route counts. Secure vision analyzes map geometry without exposing the provider API key to the app.'
                                : 'On-device OCR extracts route counts. Secure map vision is not configured in this build.'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _analyzing ? null : _importRouteScreenshots,
                              icon: _analyzing ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.collections_outlined),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(_analyzing ? 'Analyzing screenshots…' : 'Select Multiple Screenshots'),
                              ),
                            ),
                            if (_importedScreenshots.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text('${_importedScreenshots.length} screenshot${_importedScreenshots.length == 1 ? '' : 's'} attached${_visionResult == null ? '' : ' • secure vision complete'}.', textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _stops,
                      autofocus: _importedScreenshots.isEmpty,
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
                      items: const ['Residential', 'Mixed', 'Rural', 'Downtown / Urban', 'Apartment-heavy', 'Business-heavy', 'Custom']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setState(() => _routeType = value ?? 'Mixed'),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(children: [
                        ListTile(
                          leading: const Icon(Icons.query_stats_outlined),
                          title: const Text('Route difficulty inputs'),
                          subtitle: Text(_visionResult == null ? 'Optional. Add what you know for a transparent difficulty score.' : 'Map-derived values were prefilled. Review before saving.'),
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
