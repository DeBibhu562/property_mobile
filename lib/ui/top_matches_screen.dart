import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/property/property_list_controller.dart';
import '../features/property/property_models.dart';
import 'widgets/tinder_swipe_card.dart';

enum SwipeAction { connect, decideLater }

class SwipeHistoryEntry {
  const SwipeHistoryEntry({
    required this.property,
    required this.action,
  });

  final PropertyItem property;
  final SwipeAction action;
}

class TopMatchesScreen extends ConsumerStatefulWidget {
  const TopMatchesScreen({super.key, required this.onNavigate});

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<TopMatchesScreen> createState() => _TopMatchesScreenState();
}

class _TopMatchesScreenState extends ConsumerState<TopMatchesScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<SwipeHistoryEntry> _history = [];

  // Drag physics & animation state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isAnimating = false;

  late final AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _angleAnimation;

  late final AnimationController _undoController;
  late Animation<Offset> _undoAnimation;

  static const List<PropertyItem> _fallbackMatches = [
    PropertyItem(
      id: 'top-match-1',
      title: '3 BHK Ultra Luxury Apartment in DLF Phase 5',
      price: 33600000,
      city: 'Gurugram',
      locality: 'DLF Phase 5',
      listingType: 'RESIDENTIAL',
      bhk: 3,
      builtUpArea: 2150,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    ),
    PropertyItem(
      id: 'top-match-2',
      title: '2 BHK Premium High-Rise with Pool View',
      price: 13500000,
      city: 'Noida',
      locality: 'Sector 75',
      listingType: 'RESIDENTIAL',
      bhk: 2,
      builtUpArea: 1380,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
    ),
    PropertyItem(
      id: 'top-match-3',
      title: '4 BHK Luxury Sky Villa with Private Deck',
      price: 64000000,
      city: 'Bangalore',
      locality: 'Whitefield',
      listingType: 'RESIDENTIAL',
      bhk: 4,
      builtUpArea: 3800,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    ),
    PropertyItem(
      id: 'top-match-4',
      title: 'Commercial Office Space in Cyber City',
      price: 45000000,
      city: 'Gurugram',
      locality: 'DLF Cyber City',
      listingType: 'COMMERCIAL',
      bhk: 0,
      builtUpArea: 2800,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _angleAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _undoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _undoAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _undoController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      // Rotation proportional to horizontal displacement
      _dragAngle = (_dragOffset.dx / 320).clamp(-0.25, 0.25);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    const threshold = 100.0;
    final velocityX = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset.dx > threshold || velocityX > 400) {
      _animateSwipe(SwipeAction.connect);
    } else if (_dragOffset.dx < -threshold || velocityX < -400) {
      _animateSwipe(SwipeAction.decideLater);
    } else {
      _animateReset();
    }
  }

  void _animateSwipe(SwipeAction action) {
    if (_isAnimating) return;
    final items = _getActiveList();
    if (_currentIndex >= items.length) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = action == SwipeAction.connect ? screenWidth * 1.4 : -screenWidth * 1.4;
    final targetOffset = Offset(targetX, _dragOffset.dy * 0.5);
    final targetAngle = action == SwipeAction.connect ? 0.3 : -0.3;

    _isAnimating = true;

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeIn));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeIn));

    _swipeController.forward(from: 0.0).then((_) {
      final swipedProperty = items[_currentIndex];
      setState(() {
        _history.add(SwipeHistoryEntry(property: swipedProperty, action: action));
        _currentIndex++;
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isAnimating = false;
      });

      if (action == SwipeAction.connect) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected with ${swipedProperty.title}!'),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.amberAccent,
              onPressed: () => widget.onNavigate('/property-detail', swipedProperty.id),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to Decide Later (Not Decided Yet)'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.amberAccent,
              onPressed: _onUndo,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _animateReset() {
    _isAnimating = true;
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack));

    _swipeController.forward(from: 0.0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isAnimating = false;
      });
    });
  }

  void _onUndo() {
    if (_history.isEmpty || _currentIndex <= 0 || _isAnimating) return;

    final lastEntry = _history.removeLast();
    final screenWidth = MediaQuery.of(context).size.width;
    final startX = lastEntry.action == SwipeAction.connect ? screenWidth * 1.2 : -screenWidth * 1.2;

    _isAnimating = true;
    setState(() {
      _currentIndex--;
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
    });

    _undoAnimation = Tween<Offset>(
      begin: Offset(startX, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _undoController, curve: Curves.easeOutBack));

    _undoController.forward(from: 0.0).then((_) {
      setState(() {
        _isAnimating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored ${lastEntry.property.title} to deck'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    });
  }

  List<PropertyItem> _getActiveList() {
    final listState = ref.watch(propertyListControllerProvider);
    return listState.items.isNotEmpty ? listState.items : _fallbackMatches;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getActiveList();
    final remaining = math.max(0, items.length - _currentIndex);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Hand-picked Header & Match Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Today\'s Hand-picked Properties for You!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$remaining Left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Undo last decision',
                      onPressed: _onUndo,
                      icon: const Icon(Icons.undo_rounded, size: 20, color: Colors.amberAccent),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),

            // Card Deck or Caught Up Screen
            Expanded(
              child: _currentIndex >= items.length
                  ? _buildAllCaughtUpView(items)
                  : _buildCardDeck(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDeck(List<PropertyItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // 3-Card Interactive Stack
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Card 3 (Bottom)
                    if (_currentIndex + 2 < items.length)
                      _buildStackedCard(
                        property: items[_currentIndex + 2],
                        scale: 0.90,
                        offsetY: 24,
                        opacity: 0.55,
                      ),

                    // Card 2 (Middle)
                    if (_currentIndex + 1 < items.length) ...[
                      Builder(builder: (context) {
                        final dragFraction = (_dragOffset.dx.abs() / 200).clamp(0.0, 1.0);
                        final currentScale = 0.95 + (dragFraction * 0.05);
                        final currentY = 12.0 * (1.0 - dragFraction);
                        final currentOpacity = 0.85 + (dragFraction * 0.15);

                        return _buildStackedCard(
                          property: items[_currentIndex + 1],
                          scale: currentScale,
                          offsetY: currentY,
                          opacity: currentOpacity,
                        );
                      }),
                    ],

                    // Card 1 (Top Active Card)
                    if (_currentIndex < items.length)
                      _buildTopCard(items[_currentIndex]),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Action Controls: "No, Decide Later" | Floating Undo | "Yes, Connect me"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No, Decide Later Button
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () => _animateSwipe(SwipeAction.decideLater),
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                  label: const Text(
                    'No, Decide Later',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Floating Undo Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _history.isNotEmpty ? _onUndo : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _history.isNotEmpty
                          ? const Color(0xFFFEF3C7)
                          : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _history.isNotEmpty
                            ? const Color(0xFFF59E0B)
                            : Colors.white24,
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_history.isNotEmpty)
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.undo_rounded,
                          size: 24,
                          color: _history.isNotEmpty
                              ? const Color(0xFFB45309)
                              : Colors.white38,
                        ),
                        if (_history.isNotEmpty)
                          Positioned(
                            top: 6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_history.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Yes, Connect me Button
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: () => _animateSwipe(SwipeAction.connect),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Yes, Connect me',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${items.length - _currentIndex} hand-picked matches left • Swipe right to connect, left to decide later',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCard({
    required PropertyItem property,
    required double scale,
    required double offsetY,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: TinderSwipeCard(
            property: property,
            isTopCard: false,
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(PropertyItem property) {
    Widget card = TinderSwipeCard(
      property: property,
      dragDx: _dragOffset.dx,
      isTopCard: true,
      onTap: () => widget.onNavigate('/property-detail', property.id),
    );

    // Apply interactive drag or programmatic animation
    if (_swipeController.isAnimating) {
      return AnimatedBuilder(
        animation: _swipeController,
        builder: (context, child) {
          return Transform.translate(
            offset: _swipeAnimation.value,
            child: Transform.rotate(
              angle: _angleAnimation.value,
              child: child,
            ),
          );
        },
        child: card,
      );
    }

    if (_undoController.isAnimating) {
      return AnimatedBuilder(
        animation: _undoController,
        builder: (context, child) {
          return Transform.translate(
            offset: _undoAnimation.value,
            child: child,
          );
        },
        child: card,
      );
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragAngle,
          child: card,
        ),
      ),
    );
  }

  Widget _buildAllCaughtUpView(List<PropertyItem> items) {
    final connectedCount = _history.where((e) => e.action == SwipeAction.connect).length;
    final laterCount = _history.where((e) => e.action == SwipeAction.decideLater).length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'You\'re all caught up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have explored all hand-picked matches for today.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 24),

            // Summary Metrics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStat(
                    label: 'Reviewed',
                    value: '${_history.length}',
                    color: Colors.white,
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  _SummaryStat(
                    label: 'Connected',
                    value: '$connectedCount',
                    color: const Color(0xFF34D399),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  _SummaryStat(
                    label: 'Decide Later',
                    value: '$laterCount',
                    color: const Color(0xFFFBBF24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _history.clear();
                  });
                },
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Review Matches Again', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.amberAccent),
                  label: const Text('Undo Last Decision', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amberAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amberAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => widget.onNavigate('/properties'),
              icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white70),
              label: const Text('Explore More in Search', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }
}
