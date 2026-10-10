import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_error_formatter.dart';
import '../../core/flavor_config.dart';

/// A premium, reusable error and offline state widget.
/// Renders a beautiful visual indicator, clear user-friendly explanation,
/// actionable retry buttons, and optional dev diagnostics in dev mode.
class AppErrorState extends StatefulWidget {
  const AppErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.secondaryLabel,
    this.onSecondaryAction,
    this.title,
    this.message,
    this.compact = false,
    this.isDark = false,
    this.customIcon,
    this.showDevDiagnostics = true,
  });

  /// The raw or formatted error object (DioException, SocketException, String, AppNetworkException, etc.)
  final Object? error;

  /// Primary retry callback
  final Future<void> Function()? onRetry;
  final String retryLabel;

  /// Optional secondary action (e.g. "Close", "Go to Search")
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  /// Optional custom title and message overrides
  final String? title;
  final String? message;

  /// Use compact layout for bottom sheets, modals, or smaller containers
  final bool compact;

  /// Force dark theme colors (e.g. for admin screens)
  final bool isDark;

  /// Optional custom icon override
  final IconData? customIcon;

  /// Whether to show the collapsible diagnostic panel in dev builds
  final bool showDevDiagnostics;

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  bool _isRetrying = false;
  bool _showDiagnostics = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry!();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = ApiErrorFormatter.format(widget.error);
    final displayTitle = widget.title ?? parsed.title;
    final displayMessage = widget.message ?? parsed.message;
    final displayIcon = widget.customIcon ?? parsed.icon;

    final isDarkMode = widget.isDark || Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconBgColor = isDarkMode
        ? const Color(0xFF1E293B)
        : (parsed.isConnectionIssue ? const Color(0xFFEEF2FF) : const Color(0xFFFEF2F2));
    final iconColor = isDarkMode
        ? const Color(0xFF818CF8)
        : (parsed.isConnectionIssue ? const Color(0xFF4F46E5) : const Color(0xFFEF4444));

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(displayIcon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (widget.onRetry != null)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isRetrying ? null : _handleRetry,
                    child: _isRetrying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.retryLabel),
                  ),
                if (widget.onSecondaryAction != null && widget.secondaryLabel != null)
                  TextButton(
                    onPressed: widget.onSecondaryAction,
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                    ),
                    child: Text(widget.secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(displayIcon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onRetry != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isRetrying ? null : _handleRetry,
                      icon: _isRetrying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(widget.retryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  if (widget.onSecondaryAction != null && widget.secondaryLabel != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTextColor,
                        side: BorderSide(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onSecondaryAction,
                      child: Text(widget.secondaryLabel!),
                    ),
                  ],
                ],
              ),
              if (FlavorConfig.isDev && widget.showDevDiagnostics) ...[
                const SizedBox(height: 28),
                InkWell(
                  onTap: () => setState(() => _showDiagnostics = !_showDiagnostics),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showDiagnostics ? Icons.expand_less : Icons.tune_rounded,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showDiagnostics ? 'Hide dev details' : 'Show connection diagnostics',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showDiagnostics) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Target API:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                FlavorConfig.apiBaseUrl,
                                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (parsed.technicalDetails != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            parsed.technicalDetails!,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Run `npm run docker:dev` locally or use `adb reverse tcp:3000 tcp:3000`',
                                style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              tooltip: 'Copy diagnostic details',
                              onPressed: () {
                                final text = 'API Base: ${FlavorConfig.apiBaseUrl}\nError: ${parsed.technicalDetails ?? parsed.message}';
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Diagnostics copied to clipboard'), duration: Duration(seconds: 2)),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliver compatible wrapper for [AppErrorState] inside [CustomScrollView]
class AppErrorSliverState extends StatelessWidget {
  const AppErrorSliverState({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.title,
    this.message,
    this.isDark = false,
  });

  final Object? error;
  final Future<void> Function()? onRetry;
  final String retryLabel;
  final String? title;
  final String? message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppErrorState(
        error: error,
        onRetry: onRetry,
        retryLabel: retryLabel,
        title: title,
        message: message,
        isDark: isDark,
      ),
    );
  }
}
