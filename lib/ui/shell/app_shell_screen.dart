import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_persona.dart';
import '../../core/auth_session.dart';
import '../../core/role_config.dart';
import '../../core/session_provider.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../add_listing_screen.dart';
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
import '../saved_tab_screen.dart';
import '../smart_suggestions_screen.dart';
import '../top_matches_screen.dart';
import '../widgets/center_action_sheet.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/magic_top_app_bar.dart';
import 'role_dashboard_screen.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  // 'home', 'top_matches', 'post_ad', 'projects', 'you'
  String _activeTab = 'home';
  int? _navBarIndex;

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

        // For Buyer persona: Use the signature Magicbricks Shell
        if (session.persona == AppPersona.buyer) {
          final isHomeTab = _activeTab == 'home';
          return Scaffold(
            appBar: isHomeTab
                ? MagicTopAppBar(
                    onMenuTap: () => Scaffold.maybeOf(context)?.openDrawer(),
                    onNotificationTap: () => _openRoute('/leads'),
                    onPostPropertyTap: () => _openRoute('/add-property'),
                  )
                : null,
            drawer: _buildDrawer(session),
            body: _buildBuyerBody(session),
            bottomNavigationBar: CustomBottomNav(
              selectedIndex: _navBarIndex ?? -1,
              onItemSelected: (index) {
                setState(() {
                  if (_navBarIndex == index) {
                    // Tap active tab again returns to Home feed
                    _activeTab = 'home';
                    _navBarIndex = null;
                  } else {
                    _navBarIndex = index;
                    _activeTab = switch (index) {
                      0 => 'top_matches',
                      1 => 'post_ad',
                      2 => 'projects',
                      3 => 'you',
                      _ => 'home',
                    };
                  }
                });
              },
              onCenterTap: () {
                CenterActionSheet.show(
                  context,
                  onNavigate: (route, [args]) {
                    if (route == '/profile') {
                      setState(() {
                        _activeTab = 'you';
                        _navBarIndex = 3;
                      });
                    } else if (route == '/projects') {
                      setState(() {
                        _activeTab = 'projects';
                        _navBarIndex = 2;
                      });
                    } else {
                      _openRoute(route, args);
                    }
                  },
                );
              },
            ),
          );
        }

        // For Seller / Agent / Admin personas: Role-based navigation
        final tabs = RoleConfig.tabsFor(session.persona);
        var roleIndex = _navBarIndex ?? 0;
        if (roleIndex >= tabs.length) roleIndex = 0;
        final tabId = tabs[roleIndex].id;

        return Scaffold(
          appBar: roleIndex == 0
              ? MagicTopAppBar(
                  showPostProperty: session.persona == AppPersona.seller ||
                      session.persona == AppPersona.agent,
                  onNotificationTap: () => _openRoute('/leads'),
                  onPostPropertyTap: () => _openRoute('/add-property'),
                )
              : null,
          drawer: _buildDrawer(session),
          body: _buildBody(tabId, session, session.persona),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
              selectedIndex: roleIndex,
              onDestinationSelected: (i) => setState(() => _navBarIndex = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon, color: const Color(0xFF64748B)),
                      selectedIcon: Icon(t.selectedIcon, color: AppTheme.primary),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuyerBody(AuthSession session) {
    switch (_activeTab) {
      case 'top_matches':
        return TopMatchesScreen(onNavigate: _openRoute);
      case 'post_ad':
        return const AddListingScreen();
      case 'projects':
        return ProjectsListScreen(onNavigate: _openRoute);
      case 'you':
        return ProfileScreen(embedded: true, session: session);
      case 'home':
      default:
        final searchState = ref.watch(searchSelectionProvider);
        if (searchState.intent == null) {
          return const WelcomeIntentScreen();
        }
        if (searchState.city == null) {
          return const CityPickerScreen();
        }
        return SearchPortalScreen(session: session, onNavigate: _openRoute);
    }
  }

  Widget _buildDrawer(AuthSession session) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.backgroundLight,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      session.user.phone.isNotEmpty ? session.user.phone.substring(session.user.phone.length - 2) : 'MB',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.user.name.isNotEmpty ? session.user.name : session.user.phone,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            session.user.role,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: AppTheme.primary),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _activeTab = 'home';
                        _navBarIndex = null;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined, color: Colors.amber),
                    title: const Text('Top Matches'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _activeTab = 'top_matches';
                        _navBarIndex = 0;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.apartment_outlined, color: AppTheme.textPrimary),
                    title: const Text('New Projects (magicHomes)'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _activeTab = 'projects';
                        _navBarIndex = 2;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
                    title: const Text('Post Property FREE'),
                    onTap: () {
                      Navigator.pop(context);
                      _openRoute('/add-property');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calculate_outlined, color: AppTheme.textPrimary),
                    title: const Text('EMI Calculator'),
                    onTap: () {
                      Navigator.pop(context);
                      _openRoute('/emi');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_graph_rounded, color: AppTheme.textPrimary),
                    title: const Text('Property Rates & Trends'),
                    onTap: () {
                      Navigator.pop(context);
                      _openRoute('/insights');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authSessionProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        return SavedTabScreen(onNavigate: _openRoute);
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
