import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/route_repository.dart';
import 'paywall_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.repository, this.onRoutesChanged});
  final RouteRepository repository;
  final Future<void> Function()? onRoutesChanged;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _create = false;
  bool _cloudBusy = false;
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
        final response = await _accounts.signUp(email: _email.text, password: _password.text);
        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Check your email to confirm it, then sign in.')));
          setState(() => _create = false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created and signed in.')));
          setState(() {});
        }
      } else {
        await _accounts.signIn(email: _email.text, password: _password.text);
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account request failed. Check your email/password and connection, then try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupRoutes() async {
    if (_cloudBusy) return;
    setState(() => _cloudBusy = true);
    try {
      final routes = await widget.repository.completedRoutes();
      final count = await const CloudBackupService().backupCompletedRoutes(routes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count == 0 ? 'No completed routes to back up.' : 'Backed up $count completed route${count == 1 ? '' : 's'} securely.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _cloudBusy = false);
    }
  }

  Future<void> _restoreRoutes() async {
    if (_cloudBusy) return;
    setState(() => _cloudBusy = true);
    try {
      final rows = await const CloudBackupService().loadCloudRoutes();
      final count = await widget.repository.restoreCloudRoutes(rows);
      if (widget.onRoutesChanged != null) await widget.onRoutesChanged!();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count == 0 ? 'This device already has all available cloud routes.' : 'Restored $count route${count == 1 ? '' : 's'} to this device.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _cloudBusy = false);
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
          OutlinedButton.icon(onPressed: _cloudBusy ? null : _backupRoutes, icon: const Icon(Icons.cloud_upload_outlined), label: Text(_cloudBusy ? 'Working…' : 'Back Up Completed Routes')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _cloudBusy ? null : _restoreRoutes, icon: const Icon(Icons.cloud_download_outlined), label: Text(_cloudBusy ? 'Working…' : 'Restore Routes From Cloud')),
          const SizedBox(height: 6),
          Text('Cloud backup/restore requires Pro. Route records, checkpoints, and events sync; original evidence image files are not uploaded in this release.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () async { await _accounts.signOut(); if (mounted) setState(() {}); }, child: const Text('Sign Out')),
        ] else ...[
          Text(_create ? 'Create an account' : 'Sign in', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_create ? 'Create one account for AI usage, cloud features, and purchases.' : 'Sign in to use AI analysis, cloud features, and purchases across devices.'),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 14),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Please wait…' : (_create ? 'Create Account' : 'Sign In'))),
          TextButton(onPressed: _busy ? null : () => setState(() => _create = !_create), child: Text(_create ? 'Already have an account? Sign in' : 'Need an account? Create one')),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free stays useful', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Core route tracking, checkpoints, delays, local history, evidence photos, basic forecasting, and basic stats remain free. Signed-in Free accounts include 3 AI analyses per month. Pro adds expanded AI automation, advanced analytics, and cloud features.'),
            ]),
          ),
        ),
      ],
    );
  }
}
