import 'package:flutter/material.dart';
import '../services/account_service.dart';
import 'paywall_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _create = false;

  AccountService get _accounts => AccountService.instance;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
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
    try {
      await _accounts.sendMagicLink(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Magic link sent.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
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
        const SizedBox(height: 8),
        if (!_accounts.isConfigured)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Cloud accounts are not connected in this build yet. Local route tracking still works normally.'),
            ),
          )
        else if (user != null) ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.email ?? 'Signed in'),
              subtitle: const Text('Cloud account connected'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Route Performance Tracker Pro'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () async { await _accounts.signOut(); if (mounted) setState(() {}); }, child: const Text('Sign Out')),
        ] else ...[
          Text(_create ? 'Create an account' : 'Sign in', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
              Text('Why create an account?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Cloud backup, multi-device sync, subscription restore, and Pro features will attach to your account. Local route tracking remains available offline.'),
            ]),
          ),
        ),
      ],
    );
  }
}
