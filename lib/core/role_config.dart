import 'package:flutter/material.dart';

import 'app_persona.dart';

class NavTab {
  const NavTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class DashboardTask {
  const DashboardTask({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.routeArguments,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Object? routeArguments;
}

class RoleConfig {
  static List<NavTab> tabsFor(AppPersona persona) => switch (persona) {
        AppPersona.buyer => const [
            NavTab(
              id: 'home',
              label: 'Search',
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
            ),
            NavTab(
              id: 'insights',
              label: 'Insights',
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
            ),
            NavTab(
              id: 'suggestion',
              label: 'Suggestion',
              icon: Icons.lightbulb_outline,
              selectedIcon: Icons.lightbulb,
            ),
            NavTab(
              id: 'favorites',
              label: 'Saved',
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
            ),
            NavTab(
              id: 'account',
              label: 'Profile',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        AppPersona.seller => const [
            NavTab(
              id: 'overview',
              label: 'Overview',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            NavTab(
              id: 'listings',
              label: 'Listing',
              icon: Icons.home_work_outlined,
              selectedIcon: Icons.home_work,
            ),
            NavTab(
              id: 'leads',
              label: 'Leads',
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox,
            ),
            NavTab(
              id: 'account',
              label: 'Account',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        AppPersona.agent || AppPersona.agencyAdmin => const [
            NavTab(
              id: 'home',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            NavTab(
              id: 'listings',
              label: 'Listings',
              icon: Icons.apartment_outlined,
              selectedIcon: Icons.apartment,
            ),
            NavTab(
              id: 'leads',
              label: 'Leads',
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox,
            ),
            NavTab(
              id: 'account',
              label: 'Account',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        AppPersona.admin => const [
            NavTab(
              id: 'home',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            NavTab(
              id: 'moderation',
              label: 'Queue',
              icon: Icons.fact_check_outlined,
              selectedIcon: Icons.fact_check,
            ),
            NavTab(
              id: 'explore',
              label: 'Directory',
              icon: Icons.travel_explore_outlined,
              selectedIcon: Icons.travel_explore,
            ),
            NavTab(
              id: 'account',
              label: 'System',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
      };

  static List<DashboardTask> tasksFor(AppPersona persona) => switch (persona) {
        AppPersona.buyer => const [
            DashboardTask(
              title: 'Browse properties',
              subtitle: 'Search by city, BHK, and budget',
              icon: Icons.travel_explore,
              route: '/properties',
            ),
          ],
        AppPersona.seller => const [
            DashboardTask(
              title: 'Add property',
              subtitle: 'Create a new listing',
              icon: Icons.add_home_work,
              route: '/add-property',
            ),
            DashboardTask(
              title: 'My listings',
              subtitle: 'Manage rank & visibility',
              icon: Icons.list_alt,
              route: '/my-listings',
            ),
            DashboardTask(
              title: 'Lead inbox',
              subtitle: 'Respond to buyer enquiries',
              icon: Icons.inbox,
              route: '/leads',
            ),
          ],
        AppPersona.agent => const [
            DashboardTask(
              title: 'Agency listings',
              subtitle: 'View and manage listings',
              icon: Icons.apartment,
              route: '/my-listings',
            ),
            DashboardTask(
              title: 'Lead inbox',
              subtitle: 'Follow up on enquiries',
              icon: Icons.inbox,
              route: '/leads',
            ),
            DashboardTask(
              title: 'Add property',
              subtitle: 'List on behalf of owner',
              icon: Icons.add,
              route: '/add-property',
            ),
          ],
        AppPersona.agencyAdmin => const [
            DashboardTask(
              title: 'Agency listings',
              subtitle: 'Overview of active inventory',
              icon: Icons.apartment,
              route: '/my-listings',
            ),
            DashboardTask(
              title: 'Lead inbox',
              subtitle: 'Team enquiries',
              icon: Icons.inbox,
              route: '/leads',
            ),
            DashboardTask(
              title: 'Add listing',
              subtitle: 'Publish a new property',
              icon: Icons.add_business,
              route: '/add-property',
            ),
          ],
        AppPersona.admin => const [
            DashboardTask(
              title: 'Moderation queue',
              subtitle: 'Approve or reject properties',
              icon: Icons.fact_check,
              route: '/admin-moderation',
            ),
            DashboardTask(
              title: 'Browse live inventory',
              subtitle: 'Preview buyer experience',
              icon: Icons.travel_explore,
              route: '/properties',
            ),
          ],
      };

  static String welcomeTitle(AppPersona persona, String name) => switch (persona) {
        AppPersona.buyer => 'Find your next home, $name',
        AppPersona.seller => 'Manage your listings, $name',
        AppPersona.agent => 'Agency workspace, $name',
        AppPersona.agencyAdmin => 'Agency command center, $name',
        AppPersona.admin => 'Admin console, $name',
      };
}
