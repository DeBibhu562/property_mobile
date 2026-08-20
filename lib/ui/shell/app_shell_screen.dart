import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_persona.dart';
import '../../core/auth_session.dart';
import '../../core/role_config.dart';
import '../../core/session_provider.dart';
import '../../core/providers.dart';
import '../admin_moderation_screen.dart';
import '../leads_screen.dart';
import '../my_listings_screen.dart';
import '../profile_screen.dart';
import '../property_list_screen.dart';
import '../emi_calculator_screen.dart';
import '../owner_dashboard_screen.dart';
import '../agent_dashboard_screen.dart';
import '../welcome_intent_screen.dart';
import '../city_picker_screen.dart';
import '../search_portal_screen.dart';
import '../projects_list_screen.dart';
import '../buyer_insights_screen.dart';
import '../smart_suggestions_screen.dart';
import 'role_dashboard_screen.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authSessionProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Session error'))),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacementNamed('/auth');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final tabs = RoleConfig.tabsFor(session.persona);
        var index = _index;
        if (index >= tabs.length) index = 0;
        final tabId = tabs[index].id;

        return Scaffold(
          body: _buildBody(tabId, session, session.persona),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: tabs
                .map(
                  (t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildBody(String tabId, AuthSession session, AppPersona activePersona) {
    switch (tabId) {
      case 'home':
        if (activePersona == AppPersona.agent || activePersona == AppPersona.agencyAdmin || activePersona == AppPersona.admin) {
          return AgentDashboardScreen(session: session, onNavigate: _openRoute);
        }
        if (activePersona == AppPersona.buyer) {
          final searchState = ref.watch(searchSelectionProvider);
          if (searchState.intent == null) {
            return const WelcomeIntentScreen();
          }
          if (searchState.city == null) {
            return const CityPickerScreen();
          }
          return SearchPortalScreen(session: session, onNavigate: _openRoute);
        }
        return RoleDashboardScreen(
          session: session,
          onNavigate: _openRoute,
        );
      case 'overview':
        return OwnerDashboardScreen(session: session);
      case 'listings':
        if (activePersona == AppPersona.seller) {
          return OwnerDashboardScreen(session: session);
        }
        return const MyListingsScreen(embedded: true);
      case 'leads':
        return const LeadsScreen(embedded: true);
      case 'moderation':
        return const AdminModerationScreen(embedded: true);
      case 'explore':
        return PropertyListScreen(
          embedded: true,
          showAddFab: activePersona == AppPersona.seller ||
              activePersona == AppPersona.agent ||
              activePersona == AppPersona.agencyAdmin,
        );
      case 'favorites':
        return const PropertyListScreen(
          embedded: true,
          showOnlyFavorites: true,
          showAddFab: false,
        );
      case 'insights':
        return BuyerInsightsScreen(onNavigate: _openRoute);
      case 'suggestion':
        return SmartSuggestionsScreen(
          city: ref.watch(searchSelectionProvider).city ?? 'New Delhi',
          embedded: true,
        );
      case 'projects':
        return ProjectsListScreen(onNavigate: _openRoute);
      case 'emi':
        return const EmiCalculatorScreen(embedded: true);
      case 'account':
        return ProfileScreen(embedded: true, session: session);
      default:
        return RoleDashboardScreen(session: session, onNavigate: _openRoute);
    }
  }

  void _openRoute(String route, [Object? arguments]) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }
}
