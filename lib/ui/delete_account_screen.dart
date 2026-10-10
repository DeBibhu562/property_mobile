import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_nav.dart';
import '../core/providers.dart';
import '../core/session_provider.dart';
import '../features/auth/account_deletion_models.dart';
import 'widgets/app_error_state.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  late Future<AccountDeletionPolicy> _policyFuture;
  final _phraseController = TextEditingController();
  bool _understandsPermanent = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _policyFuture = _fetchPolicy();
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  Future<AccountDeletionPolicy> _fetchPolicy() {
    return ref.read(authRepositoryProvider).getAccountDeletionPolicy();
  }

  void _retryPolicy() {
    setState(() {
      _policyFuture = _fetchPolicy();
    });
  }

  bool _isDeleteEnabled(AccountDeletionPolicy policy) {
    if (_isSubmitting) return false;
    if (!_understandsPermanent) return false;
    final entered = _phraseController.text.trim();
    final expected = policy.confirmation.trim();
    return entered == expected;
  }

  Future<void> _handleDelete(AccountDeletionPolicy policy) async {
    if (!_isDeleteEnabled(policy)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Final Confirmation'),
          ],
        ),
        content: const Text(
          'Are you absolutely sure you want to permanently delete your account? '
          'All your active listings and data will be removed immediately. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Permanently Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authSessionProvider.notifier).deleteAccount(policy.confirmation);
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      appMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Your account has been deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (e is DioException && e.response?.statusCode == 403) {
        _showAdminForbiddenDialog(policy.supportEmail ?? 'support@propertydilado.com');
      } else {
        String msg = 'Failed to delete account. Please try again.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['error'] is String) {
            msg = data['error'] as String;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAdminForbiddenDialog(String supportEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Account Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administrator accounts cannot self-delete from the mobile app. '
              'Please contact our support team to request administrative account closure.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      supportEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Email'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: supportEmail));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support email copied to clipboard.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyWebUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Web deletion link copied. Open it in your browser to proceed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete account'),
      ),
      body: FutureBuilder<AccountDeletionPolicy>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final policy = snapshot.data ?? const AccountDeletionPolicy();
          return _buildContent(context, policy, errorColor);
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return AppErrorState(
      error: error,
      title: 'Could Not Load Deletion Policy',
      onRetry: () async => _retryPolicy(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AccountDeletionPolicy policy,
    Color errorColor,
  ) {
    final theme = Theme.of(context);
    final isEnabled = _isDeleteEnabled(policy);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning Card Header
          Card(
            color: errorColor.withValues(alpha: 0.08),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: errorColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: errorColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permanent Account Deletion',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.deletesImmediately
                              ? 'Deleting your account is permanent. All associated data and listings will be removed immediately.'
                              : 'Deleting your account is permanent. Your data removal request will be processed.',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Removes list
          if (policy.removes.isNotEmpty) ...[
            Text(
              'What will be removed permanently:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  children: policy.removes
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.remove_circle_outline, color: errorColor, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Dynamic Retains list
          if (policy.retains.isNotEmpty) ...[
            Text(
              'What will be retained for regulatory compliance:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  children: policy.retains
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Web alternative link
          if (policy.webUrl != null && policy.webUrl!.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.language, size: 22),
                title: const Text('Prefer deleting via the web portal?'),
                subtitle: Text(
                  policy.webUrl!,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy web deletion URL',
                  onPressed: () => _copyWebUrl(policy.webUrl!),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // Checkbox confirmation
          CheckboxListTile(
            value: _understandsPermanent,
            onChanged: _isSubmitting
                ? null
                : (val) {
                    setState(() => _understandsPermanent = val ?? false);
                  },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I understand that deleting my account is permanent and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // Typed phrase confirmation
          Text(
            'To confirm, type "${policy.confirmation}" below:',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phraseController,
            enabled: !_isSubmitting,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type ${policy.confirmation} to confirm',
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _phraseController.text.trim() == policy.confirmation
                      ? Colors.green
                      : errorColor,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isEnabled ? () => _handleDelete(policy) : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_forever),
            label: Text(
              _isSubmitting ? 'Deleting account...' : 'Permanently delete account',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
