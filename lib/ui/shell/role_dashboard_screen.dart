import 'package:flutter/material.dart';

import '../../core/app_persona.dart';
import '../../core/auth_session.dart';
import '../../core/role_config.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    super.key,
    required this.session,
    required this.onNavigate,
  });

  final AuthSession session;
  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  Widget build(BuildContext context) {
    final tasks = RoleConfig.tasksFor(session.persona);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.persona.label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(session.user.role),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            RoleConfig.welcomeTitle(session.persona, session.user.name),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitleFor(session.persona),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text('Your tasks', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...tasks.map(
            (task) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(task.icon, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: Text(task.title),
                subtitle: Text(task.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onNavigate(task.route, task.routeArguments),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(AppPersona persona) => switch (persona) {
        AppPersona.buyer => 'Search verified listings and send enquiries.',
        AppPersona.seller => 'Track listings, verification, and buyer leads.',
        AppPersona.agent => 'Work your agency pipeline from one place.',
        AppPersona.agencyAdmin => 'Oversee listings and team enquiries.',
        AppPersona.admin => 'Moderate properties and monitor inventory.',
      };
}
