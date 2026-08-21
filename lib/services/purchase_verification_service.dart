import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_service.dart';

class PurchaseVerificationService {
  const PurchaseVerificationService();

  static const _backendBaseUrl = String.fromEnvironment(
    'RPT_BACKEND_BASE_URL',
    defaultValue: 'https://route-performance-tracker-vision.vercel.app',
  );

  Future<bool> verifyGooglePlay(PurchaseDetails purchase) async {
    final accounts = AccountService.instance;
    if (!accounts.isInitialized || accounts.currentUser == null) {
      throw StateError('Sign in before activating Pro.');
    }

    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Your account session has expired. Sign in again.');
    }

    final purchaseToken = purchase.verificationData.serverVerificationData;
    if (purchaseToken.isEmpty) throw StateError('Store purchase token was missing.');

    final uri = Uri.parse('${_backendBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/verify-google-play');
    final response = await http.post(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) return true;
    if (response.statusCode == 401) throw StateError('Please sign in again before restoring Pro.');
    if (response.statusCode == 503) throw StateError('Subscription verification is not configured yet.');
    throw StateError('The store purchase could not be verified.');
  }
}
