import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/route_repository.dart';
import 'paywall_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.repository});
  final RouteRepository repository;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _create = false;
  bool _backingUp = false;
  AccountService get _accounts => AccountService.instance;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email and password.')));
      return;
    }
    setState(() => _busy = true);
    try {
      if (_create) {
        await _accounts.signUp(email: _email.text, password: _password.text);
      } else {
        await _accounts.signIn(email: _email.text, password: _password.text);
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _magicLink() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email first.')));
      return;
    }
    try {
      await _accounts.sendMagicLink(_email.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in link sent. Check your email.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _backupRoutes() async {
    if (_backingUp) return;
    setState(() => _backingUp = true);
    try {
      final routes = await widget.repository.completedRoutes();
      final count = await const CloudBackupService().backupCompletedRoutes(routes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count == 0 ? 'No completed routes to back up.' : 'Backed up $count completed route${count == 1 ? '' : 's'} securely.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _accounts.currentUser;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Account', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Your routes remain available locally even when you are signed out or offline.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        if (!_accounts.isConfigured)
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Cloud accounts are unavailable in this build. Local route tracking still works normally.')))
        else if (user != null) ...[
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(user.email ?? 'Signed in'), subtitle: const Text('Account connected'))),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Compare Free and Pro'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _backingUp ? null : _backupRoutes, icon: const Icon(Icons.cloud_upload_outlined), label: Text(_backingUp ? 'Backing up…' : 'Back Up Completed Routes')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () async { await _accounts.signOut(); if (mounted) setState(() {}); }, child: const Text('Sign Out')),
        ] else ...[
          Text(_create ? 'Create an account' : 'Sign in', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_create ? 'Create one account for backup, sync, and purchases.' : 'Sign in to access backup, sync, and purchases across devices.'),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 14),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Please wait…' : (_create ? 'Create Account' : 'Sign In'))),
          TextButton(onPressed: _busy ? null : () => setState(() => _create = !_create), child: Text(_create ? 'Already have an account? Sign in' : 'Need an account? Create one')),
          TextButton(onPressed: _busy ? null : _magicLink, child: const Text('Email me a sign-in link')),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free stays useful', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Core route tracking, checkpoints, delays, local history, evidence photos, basic forecasting, and basic stats remain free. Pro adds heavier AI automation, advanced analytics, cloud features, and expanded reports.'),
            ]),
          ),
        ),
      ],
    );
  }
}
