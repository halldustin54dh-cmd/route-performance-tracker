import '../models/user_entitlement.dart';
import 'account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntitlementService {
  const EntitlementService();

  Future<UserEntitlement> current() async {
    final accounts = AccountService.instance;
    final user = accounts.currentUser;
    if (!accounts.isInitialized || user == null) return UserEntitlement.free;

    final row = await Supabase.instance.client
        .from('entitlements')
        .select('tier,provider,product_id,expires_at,status')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null || row['tier'] != 'pro' || row['status'] != 'active') {
      return UserEntitlement.free;
    }

    return UserEntitlement(
      tier: EntitlementTier.pro,
      provider: row['provider'] as String?,
      productId: row['product_id'] as String?,
      expiresAt: row['expires_at'] == null ? null : DateTime.tryParse(row['expires_at'] as String),
    );
  }
}
