import 'dart:async';
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
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _messages = SubscriptionService.instance.messages.listen((message) {
      if (!mounted) return;
      setState(() => _message = message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
    _load();
  }

  @override
  void dispose() {
    _messages?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await SubscriptionService.instance.initialize();
    final products = await SubscriptionService.instance.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
      if (products.isEmpty) _message = 'Subscriptions are not available from this store account yet.';
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
          Text('Turn route data into route intelligence.', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Free handles everyday route tracking. Pro adds the automation, history, and deeper analysis that become more valuable the longer you use the app.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          const _PlanCard(
            title: 'Free',
            subtitle: 'Useful without paying',
            features: [
              'Unlimited route, checkpoint, and delay logging',
              'Basic finish-time forecasting and route stats',
              'Local route history and evidence photos',
              '3 AI screenshot analyses each month',
            ],
          ),
          const SizedBox(height: 12),
          const _PlanCard(
            title: 'Pro',
            subtitle: 'For drivers who want the app to do more of the thinking',
            highlighted: true,
            features: [
              'Unlimited AI screenshot and route-map analysis',
              'Automatic pick-sheet and itinerary extraction',
              'Advanced forecasting, difficulty, and historical trends',
              'Cloud backup and multi-device sync',
              'Advanced reports, evidence exports, and comparisons',
            ],
          ),
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
          const Text('Prices and billing periods are shown by your app store. A purchase is verified by our server before Pro access is activated.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.subtitle, required this.features, this.highlighted = false});
  final String title;
  final String subtitle;
  final List<String> features;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlighted ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(feature)),
            ]),
          )),
        ]),
      ),
    );
  }
}
