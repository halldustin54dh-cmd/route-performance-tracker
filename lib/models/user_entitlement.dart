enum EntitlementTier { free, pro }

class UserEntitlement {
  const UserEntitlement({
    required this.tier,
    this.provider,
    this.productId,
    this.expiresAt,
  });

  final EntitlementTier tier;
  final String? provider;
  final String? productId;
  final DateTime? expiresAt;

  bool get isPro => tier == EntitlementTier.pro &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  static const free = UserEntitlement(tier: EntitlementTier.free);
}
