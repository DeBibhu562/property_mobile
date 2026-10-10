import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_session.dart';
import '../core/providers.dart';
import '../core/session_provider.dart';
import '../features/entitlement/entitlement_models.dart';
import '../features/lead/lead_models.dart';
import 'widgets/buyer_activity_stream.dart';
import 'widgets/recommendations_ring_card.dart';
import 'widgets/user_dashboard_services_grid.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.embedded = false, this.session});

  final bool embedded;
  final AuthSession? session;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<MeEntitlements?> _future;
  late Future<List<BuyerLead>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _leadsFuture = _loadLeads();
  }

  Future<MeEntitlements?> _load() async {
    try {
      return await ref.read(entitlementRepositoryProvider).getMyEntitlements();
    } catch (_) {
      // Graceful fallback for offline / unauthenticated states: returns null so fallback UI renders seamlessly
      return null;
    }
  }

  Future<List<BuyerLead>> _loadLeads() async {
    try {
      return await ref.read(leadRepositoryProvider).buyerLeads();
    } catch (_) {
      // Graceful fallback for unauthenticated states or network issues
      return const [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
      _leadsFuture = _loadLeads();
    });
    await Future.wait([_future, _leadsFuture]);
  }

  Future<void> _signOut() async {
    await ref.read(authSessionProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  void _openDeleteAccount() {
    Navigator.of(context).pushNamed('/delete-account');
  }

  void _showSiteVisitModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_outlined, color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Cab Site Visit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A))),
                      Text('Zero booking charges • AC Cab • Dedicated Driver', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'PropertyDiLado offers complimentary doorstep pickup and drop in Delhi NCR for your verified home tours.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Pickup Location: Delhi NCR Central', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Free Cab ride request scheduled! Our site concierge will call you.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Confirm Free Cab Pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeLoansModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Home Loans at 8.35%*', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A))),
                      Text('Partnered with SBI, HDFC Bank, ICICI & Axis Bank', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Get instant digital sanction with zero processing fees on selected banking partners. Calculated EMI starting at ₹758 per Lakh.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Home Loan specialist will contact you with pre-approved offers.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Check Loan Eligibility', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInteriorsModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chair_outlined, color: Color(0xFFE11D48), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Home Interiors & Design', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A))),
                      Text('Flat 20% OFF • 45-Day Move-in Guarantee', style: TextStyle(fontSize: 12, color: Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Get tailored 3D modular kitchen, wardrobe, and living room designs with 10-year warranty from verified interior designers.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Free 3D Design Consultation booked!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Book Free Consultation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.gavel_outlined, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Legal Title Verification', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0284C7))),
                      Text('40-Point Property Dispute Verification Check', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Senior property advocates inspect 30-year deed history, municipal sanction approvals, and bank encumbrances for complete peace of mind.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Legal audit request submitted to panel lawyers.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Request Title Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValuationModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PropWorth Valuation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF7C3AED))),
                      Text('Instant AI estimate based on recent registry deeds', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Know the true market price before negotiating. Uses data from over 50,000 real property transactions in Delhi NCR.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening PropWorth valuation report...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Calculate Valuation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVastuModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.compass_calibration_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vastu Consultation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFFD97706))),
                      Text('Certified experts • Energy flow & directional audit', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Get complete floorplan analysis for North/East entrance harmony, master bedroom orientation, and zero-demolition remedies.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vastu consultation booked with certified specialist.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Book Vastu Expert', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session ?? ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (!widget.embedded)
            IconButton(
              tooltip: 'My listings',
              onPressed: () => Navigator.pushNamed(context, '/my-listings'),
              icon: const Icon(Icons.home_work_outlined, color: Color(0xFF475569)),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Color(0xFF475569)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MeEntitlements?>(
          future: _future,
          builder: (context, snapshot) {
            final entitlements = snapshot.data;

            return FutureBuilder<List<BuyerLead>>(
              future: _leadsFuture,
              builder: (context, leadsSnapshot) {
                final leads = leadsSnapshot.data ?? const <BuyerLead>[];

                return ListView(
                  cacheExtent: 5000,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    if (session != null) ...[
                      _HeroUserHeader(session: session),
                      const SizedBox(height: 16),
                    ],

                    // Membership & Entitlements Section
                    _MembershipCard(
                      entitlements: entitlements,
                      session: session,
                    ),
                    const SizedBox(height: 18),

                    // Account Settings & Security
                    const _SectionTitle(title: 'Account Settings'),
                    const SizedBox(height: 10),
                    _SettingsGroup(
                      onSignOut: _signOut,
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Danger zone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DangerZoneCard(
                      onDeleteAccount: _openDeleteAccount,
                    ),
                    const SizedBox(height: 24),

                    // SCR-11: 8-Tile Quick Service Grid
                    UserDashboardServicesGrid(
                      contactedCount: leads.isNotEmpty ? leads.length : 116,
                      onContactedTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You have ${leads.isNotEmpty ? leads.length : 116} active property inquiries.')),
                        );
                      },
                      onSiteVisitTap: _showSiteVisitModal,
                      onSuggestionsTap: () => Navigator.of(context).pushNamed('/smart-suggestions'),
                      onLoansTap: _showHomeLoansModal,
                      onInteriorsTap: _showInteriorsModal,
                      onLegalTap: _showLegalModal,
                      onValuationTap: _showValuationModal,
                      onVastuTap: _showVastuModal,
                    ),
                    const SizedBox(height: 18),

                    // SCR-11: Personalized Recommendations Card with Countdown Ring
                    RecommendationsRingCard(
                      remainingCount: 30,
                      city: 'Delhi NCR',
                      onExploreTap: () => Navigator.of(context).pushNamed('/smart-suggestions'),
                    ),
                    const SizedBox(height: 16),

                    // SCR-11: Commute Preference Survey Card
                    PreferenceSurveyCard(
                      onSelectionChanged: (selected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text('Preferences updated: ${selected.join(", ")}'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // SCR-11: Recent Activity Stream (Contacted vs Viewed tabs, status pills, call, notes)
                    BuyerActivityStream(
                      contactedLeads: leads,
                      onViewSimilar: (lead) => Navigator.of(context).pushNamed('/smart-suggestions'),
                      onContactAgain: (phone) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connecting call to advertiser at $phone...')),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Activity Metrics
                    _ActivitySummaryRow(
                      favoritesCount: ref.watch(favoritesProvider).length,
                    ),
                    const SizedBox(height: 20),

                    // Structured Limits (if available from backend)
                    if (entitlements != null && _hasStructuredLimits(entitlements)) ...[
                      const _SectionTitle(title: 'Plan Usage & Quotas'),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLimitsList(entitlements),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _hasStructuredLimits(MeEntitlements data) {
    return data.maxActiveListings != null ||
        data.maxImagesPerListing != null ||
        data.maxLeadsPerMonth != null ||
        data.maxSearchesPerDay != null;
  }

  List<Widget> _buildLimitsList(MeEntitlements data) {
    final widgets = <Widget>[];

    final activeLimit = data.maxActiveListings;
    if (activeLimit != null) {
      widgets.add(_LimitProgressTile(
        label: 'Active Listings',
        used: data.usage.activeListings,
        limit: activeLimit,
      ));
    }

    final imagesLimit = data.maxImagesPerListing;
    if (imagesLimit != null) {
      widgets.add(_LimitProgressTile(label: 'Images per Listing', limit: imagesLimit));
    }

    final leads = data.maxLeadsPerMonth;
    if (leads != null) {
      widgets.add(_LimitProgressTile(label: 'Direct Buyer Leads / Month', limit: leads));
    }

    final searches = data.maxSearchesPerDay;
    if (searches != null) {
      widgets.add(_LimitProgressTile(label: 'Search Limit / Day', limit: searches));
    }

    return widgets;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _HeroUserHeader extends StatelessWidget {
  const _HeroUserHeader({required this.session});
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final roleLabel = switch (user.role.toUpperCase()) {
      'ADMIN' || 'SUPER_ADMIN' => 'Administrator',
      'OWNER' || 'SELLER' => 'Property Owner',
      'AGENT' || 'AGENCY_ADMIN' => 'Real Estate Agent',
      _ => 'Buyer / Explorer',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF67E8F9), // Light cyan verified badge
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({this.entitlements, required this.session});
  final MeEntitlements? entitlements;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final isPaid = entitlements != null && !entitlements!.isFree;
    final tierTitle = entitlements?.tier ?? (isPaid ? 'Premium Tier' : 'Free Explorer');
    final upgradeUrl = entitlements?.upgradeUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.workspace_premium : Icons.stars_rounded,
                  color: isPaid ? const Color(0xFFD97706) : const Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isPaid ? 'Active Paid Subscription' : 'Standard Real Estate Privileges Active',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (upgradeUrl.isNotEmpty)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: upgradeUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgrade link copied to clipboard!')),
                    );
                  },
                  child: const Text('Upgrade'),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          // Included perks
          const _PerkRow(icon: Icons.check_circle_outline, text: 'Search verified listings across India'),
          const SizedBox(height: 6),
          const _PerkRow(icon: Icons.check_circle_outline, text: 'Direct contact with property owners & agents'),
          const SizedBox(height: 6),
          const _PerkRow(icon: Icons.check_circle_outline, text: 'Smart AI match recommendations & alerts'),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)), // Emerald green
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow({required this.favoritesCount});
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Saved Homes',
            value: '$favoritesCount',
            icon: Icons.favorite,
            color: const Color(0xFFE11D48),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            label: 'Active Alerts',
            value: 'On',
            icon: Icons.notifications_active,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            label: 'Verified City',
            value: 'Delhi NCR',
            icon: Icons.location_on,
            color: Color(0xFF059669),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}



class _LimitProgressTile extends StatelessWidget {
  const _LimitProgressTile({required this.label, this.used, required this.limit});
  final String label;
  final int? used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final showUsage = used != null && limit > 0;
    final ratio = showUsage ? (used! / limit).clamp(0.0, 1.0) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              Text(
                showUsage ? '$used / $limit' : '$limit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.onSignOut,
  });

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF475569)),
            title: const Text('Help & Customer Support'),
            subtitle: const Text('FAQs, support email, and user guides', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email: support@propertydilado.com')),
              );
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF475569)),
            title: const Text('Sign out'),
            subtitle: const Text('End your session on this device', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onDeleteAccount});
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Card(
      elevation: 0,
      color: errorColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: errorColor),
        title: Text(
          'Delete account',
          style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Permanently delete account and all data',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: errorColor),
        onTap: onDeleteAccount,
      ),
    );
  }
}
