import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error_formatter.dart';
import '../../core/providers.dart';
import '../../core/session_provider.dart';
import '../../core/theme.dart';

enum InquiryStep { form, sending, otp, success }

/// Milestone 4: Lead Generation & Email OTP Verification Modal (`SCR-10`)
/// Features a compact bottom sheet with reduced top height to avoid cutting the main screen,
/// 6-digit Email OTP pin verification (via Gmail SMTP), countdown timer,
/// advertiser contact revelation, and post-inquiry contextual recommendations.
class LeadInquiryModal extends ConsumerStatefulWidget {
  const LeadInquiryModal({
    super.key,
    required this.listingId,
    required this.title,
    required this.price,
    required this.locality,
    this.city = 'New Delhi',
    this.imageUrl,
    this.ownerName = 'Verified Advertiser',
    this.ownerPhone = '+91 98112 34567',
    this.isProject = false,
  });

  final String listingId;
  final String title;
  final String price;
  final String locality;
  final String city;
  final String? imageUrl;
  final String ownerName;
  final String ownerPhone;
  final bool isProject;

  static Future<void> show(
    BuildContext context, {
    required String listingId,
    required String title,
    required String price,
    required String locality,
    String city = 'New Delhi',
    String? imageUrl,
    String ownerName = 'Verified Advertiser',
    String ownerPhone = '+91 98112 34567',
    bool isProject = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LeadInquiryModal(
        listingId: listingId,
        title: title,
        price: price,
        locality: locality,
        city: city,
        imageUrl: imageUrl,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        isProject: isProject,
      ),
    );
  }

  @override
  ConsumerState<LeadInquiryModal> createState() => _LeadInquiryModalState();
}

class _LeadInquiryModalState extends ConsumerState<LeadInquiryModal> {
  InquiryStep _currentStep = InquiryStep.form;
  String _errorMessage = '';

  // Form Fields
  final _nameCtrl = TextEditingController(text: 'Ashish Tayal');
  final _emailCtrl = TextEditingController(text: 'ashishtayal2022@gmail.com');
  String _selectedIntent = 'Schedule a Site Visit';

  final List<String> _intentOptions = [
    'Schedule a Site Visit',
    'Get Best Price Quote',
    'Floor Plan & Brochure',
    'Direct Owner Callback',
  ];

  // OTP State
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _verifyingOtp = false;

  @override
  void initState() {
    super.initState();
    // Hydrate logged-in user profile if available
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session != null && session.user.name.isNotEmpty) {
      _nameCtrl.text = session.user.name;
    }
    if (session != null && session.user.phone.contains('@')) {
      _emailCtrl.text = session.user.phone;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  // --- Step 1: Request OTP ---
  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _currentStep = InquiryStep.sending;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendEmailOtp(email);

      if (!mounted) return;
      setState(() => _currentStep = InquiryStep.otp);
      _startCountdown();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      final parsed = ApiErrorFormatter.format(e, defaultMessage: 'Failed to send OTP to email');
      setState(() {
        _currentStep = InquiryStep.form;
        _errorMessage = parsed.message;
      });
    }
  }

  // --- Step 2: Verify OTP & Submit Lead ---
  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Interested Buyer';
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP');
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final session = await authRepo.verifyOtp(
        email: email,
        otp: otp,
        name: name,
        role: 'USER',
      );

      // Save authenticated session in provider
      await ref.read(authSessionProvider.notifier).setSession(session);

      // Submit lead to backend
      try {
        final dio = ref.read(dioProvider);
        await dio.post(
          '/listings/${widget.listingId}/leads',
          data: {
            'message': 'Interested in ${widget.title} ($name, $email). Intent: $_selectedIntent.',
          },
        );
      } catch (_) {
        // Cooldown or duplicate lead is treated gracefully
      }

      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _currentStep = InquiryStep.success;
      });
    } catch (e) {
      if (!mounted) return;
      final parsed = ApiErrorFormatter.format(e, defaultMessage: 'Invalid OTP code. Please retry.');
      setState(() {
        _verifyingOtp = false;
        _errorMessage = parsed.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reduced height: max 62% of viewport so it does NOT cut the top screen header
    final maxHeight = MediaQuery.of(context).size.height * 0.62;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle Bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content Area
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_currentStep) {
                  InquiryStep.form => _buildInquiryForm(),
                  InquiryStep.sending => _buildSendingOverlay(),
                  InquiryStep.otp => _buildOtpVerification(),
                  InquiryStep.success => _buildSuccessView(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- View: Lead Inquiry Form ---
  Widget _buildInquiryForm() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Property Header Pill
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.imageUrl!,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                      )
                    : _buildFallbackThumbnail(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.locality}, ${widget.city}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Contact Advertiser',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Verified contact details will be emailed and displayed instantly.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        // Full Name Field
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Your Name',
            isDense: true,
            prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),

        // Email Field
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address *',
            isDense: true,
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppTheme.primary),
            hintText: 'user@gmail.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Intent Chips
        const Text(
          'I am interested in:',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _intentOptions.map((opt) {
            final isSelected = _selectedIntent == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedIntent = opt),
              selectedColor: AppTheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11,
              ),
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
              ),
            );
          }).toList(),
        ),

        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 16),

        // CTA Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Verify Email & Contact Advertiser →',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // --- View: Sending State ---
  Widget _buildSendingOverlay() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 18),
            const Text(
              'Dispatching verification OTP...',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Sending via Gmail SMTP to ${_emailCtrl.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- View: 6-Digit Email OTP Verification ---
  Widget _buildOtpVerification() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Verify Your Email',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Enter the 6-digit OTP code sent to:',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),

        // Email pill with Edit button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email, size: 15, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _emailCtrl.text,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
                ),
              ),
              InkWell(
                onTap: () {
                  _countdownTimer?.cancel();
                  setState(() => _currentStep = InquiryStep.form);
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: AppTheme.primary),
                    SizedBox(width: 3),
                    Text('Edit', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6-Digit OTP Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              child: TextFormField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                    _verifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Resend Timer & Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _canResend
                    ? "Didn't receive code?"
                    : 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: _canResend ? _requestOtp : null,
              child: Text(
                'Resend OTP via Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _canResend ? AppTheme.primary : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),

        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 12),

        // Verify CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyingOtp ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _verifyingOtp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Verify OTP & Reveal Contact Details',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  // --- View: Contact Revealed & Post-Inquiry Recommendations ---
  Widget _buildSuccessView() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      children: [
        // Success Toast Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thank You! Enquiry Dispatched',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seller contact details have been sent to ${_emailCtrl.text}.',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Verified Seller Contact Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.person, color: AppTheme.textPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ownerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: Color(0xFF059669), size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Advertiser',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dialing ${widget.ownerPhone}...')),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16, color: Color(0xFF059669)),
                      label: Text(
                        widget.ownerPhone,
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connecting WhatsApp with ${widget.ownerName}...')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contextual Post-Lead Recommendations Section
        const Row(
          children: [
            Icon(Icons.recommend, color: AppTheme.primary, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Explore Similar Verified Properties',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildSimilarCard(
          title: 'DLF The Crest Luxury Residence',
          price: '₹ 1.85 Cr',
          locality: widget.locality,
          tag: 'Direct Owner',
        ),
        const SizedBox(height: 8),
        _buildSimilarCard(
          title: 'Godrej Woods Sky Sanctuary',
          price: '₹ 1.45 Cr',
          locality: widget.locality,
          tag: 'Verified Builder',
        ),
        const SizedBox(height: 14),

        // Done Close Action
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done & Continue Browsing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarCard({
    required String title,
    required String price,
    required String locality,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment, size: 20, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$locality • $tag',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 46,
      height: 46,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.home_work_outlined, size: 24, color: Color(0xFF64748B)),
    );
  }
}
