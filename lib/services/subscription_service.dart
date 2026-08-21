import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const monthlyId = 'route_tracker_pro_monthly';
  static const yearlyId = 'route_tracker_pro_yearly';
  static const productIds = <String>{monthlyId, yearlyId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();

  Stream<PurchaseDetails> get purchases => _purchaseController.stream;

  Future<bool> get isAvailable => _iap.isAvailable();

  Future<void> initialize() async {
    _subscription ??= _iap.purchaseStream.listen((items) async {
      for (final purchase in items) {
        _purchaseController.add(purchase);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    });
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!await _iap.isAvailable()) return const [];
    final response = await _iap.queryProductDetails(productIds);
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _purchaseController.close();
  }
}
