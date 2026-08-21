import 'package:flutter_test/flutter_test.dart';
import 'package:route_performance_tracker/models/user_entitlement.dart';

void main() {
  test('free entitlement is not Pro', () {
    expect(UserEntitlement.free.isPro, isFalse);
  });

  test('active Pro entitlement is Pro', () {
    final entitlement = UserEntitlement(
      tier: EntitlementTier.pro,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    expect(entitlement.isPro, isTrue);
  });

  test('expired Pro entitlement is not Pro', () {
    final entitlement = UserEntitlement(
      tier: EntitlementTier.pro,
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(entitlement.isPro, isFalse);
  });
}
