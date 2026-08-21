import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/route_evidence.dart';

void main() {
  test('suggested evidence filename includes date, padded stop, and sanitized label', () {
    final evidence = RouteEvidence(
      filePath: '/tmp/example.jpg',
      timestamp: DateTime(2026, 8, 20, 13, 4),
      type: EvidenceType.incidentEvidence,
      stopNumber: 46,
      relatedEventType: 'Wrong Address',
    );

    expect(evidence.suggestedFileName, '2026-08-20_Stop046_WrongAddress');
  });

  test('suggested filename falls back to evidence type when no event is linked', () {
    final evidence = RouteEvidence(
      filePath: '/tmp/example.jpg',
      timestamp: DateTime(2026, 8, 20),
      type: EvidenceType.routeDocumentation,
      stopNumber: 1,
    );

    expect(evidence.suggestedFileName, '2026-08-20_Stop001_RouteDocumentation');
  });
}
