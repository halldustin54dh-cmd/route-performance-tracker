import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<ProductDetails> _products = const [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SubscriptionService.instance.initialize();
    final products = await SubscriptionService.instance.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
      if (products.isEmpty) _message = 'Subscription products are not available in this build/store account yet.';
    });
  }

  Future<void> _buy(ProductDetails product) async {
    try {
      await SubscriptionService.instance.buy(product);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Route Performance Tracker Pro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 64),
          const SizedBox(height: 14),
          Text('More route intelligence. Less manual work.', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const _Feature(icon: Icons.auto_awesome_outlined, title: 'AI route screenshot analysis', body: 'Analyze route maps and route structure securely.'),
          const _Feature(icon: Icons.cloud_done_outlined, title: 'Cloud backup & sync', body: 'Keep route history backed up and available across devices.'),
          const _Feature(icon: Icons.insights_outlined, title: 'Advanced analytics', body: 'Deeper historical comparisons, forecasting, and route trends.'),
          const _Feature(icon: Icons.description_outlined, title: 'Enhanced reports', body: 'Expanded evidence and performance exports.'),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_message ?? 'Subscriptions unavailable.')))
          else
            ..._products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton(
                onPressed: () => _buy(product),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Expanded(child: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(product.price),
                  ]),
                ),
              ),
            )),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: SubscriptionService.instance.restore, icon: const Icon(Icons.restore), label: const Text('Restore Purchases')),
          const SizedBox(height: 12),
          const Text('Purchases must be verified by the server before Pro access is granted. Store availability and prices come from Google Play or the App Store.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(body),
    ),
  );
}
