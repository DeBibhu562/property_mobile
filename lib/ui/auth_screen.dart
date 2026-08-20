import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/session_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phone = TextEditingController(text: '9876543210');
  final _otp = TextEditingController(text: '123456');
  final _name = TextEditingController(text: 'Mobile User');
  final _adminId = TextEditingController(text: '+919900000001');
  final _adminPassword = TextEditingController(text: 'Admin@123');

  String _signupRole = 'USER';
  bool _otpSent = false;
  bool _showAdminPanel = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _name.dispose();
    _adminId.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  String _getFullPhone() {
    final raw = _phone.text.trim();
    if (raw.startsWith('+')) return raw;
    return '+91$raw';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final phoneVal = _getFullPhone();
      await ref.read(authRepositoryProvider).sendOtp(phoneVal);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _info = 'OTP sent. Dev OTP is 123456.';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final errMsg = data is Map ? data['error']?.toString() : null;
        setState(() => _error = errMsg ?? e.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final phoneVal = _getFullPhone();
      final session = await ref.read(authRepositoryProvider).verifyOtp(
            phone: phoneVal,
            otp: _otp.text.trim(),
            name: _name.text.trim(),
            role: _signupRole,
          );
      await ref.read(authSessionProvider.notifier).setSession(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final errMsg = data is Map ? data['error']?.toString() : null;
        setState(() => _error = errMsg ?? e.message ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adminLogin() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final session = await ref.read(authRepositoryProvider).adminLogin(
            identifier: _adminId.text.trim(),
            password: _adminPassword.text,
          );
      await ref.read(authSessionProvider.notifier).setSession(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final errMsg = data is Map ? data['error']?.toString() : null;
        setState(() => _error = errMsg ?? e.message ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _showAdminPanel
          ? SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => setState(() => _showAdminPanel = false),
                    ),
                  ),
                  Expanded(
                    child: _AdminPanel(
                      identifier: _adminId,
                      password: _adminPassword,
                      busy: _busy,
                      error: _error,
                      onLogin: _adminLogin,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Top Skip and Admin buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _showAdminPanel = true),
                        icon: Icon(Icons.admin_panel_settings, color: Colors.grey.shade300, size: 20),
                        tooltip: 'Admin Login',
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                        child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 10),
                        // App Logo
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'P',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        const Text(
                          'Log in or sign up to Propertely',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Buy', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('•', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            Text('Rent', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('•', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            Text('Sell', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Error/Info
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        if (_info != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_info!, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                          ),

                        if (!_otpSent) ...[
                          // Input Field
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                const Text(
                                  '+91',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '9614544971',
                                      hintStyle: TextStyle(color: Colors.black26),
                                    ),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // OTP Verification input
                          TextField(
                            controller: _otp,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Enter 6-digit OTP',
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _name,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Your display name',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), // Purple
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _busy
                                ? null
                                : (_otpSent ? _verifyOtp : _sendOtp),
                            child: _busy
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _otpSent ? 'Verify & Log in' : 'Continue',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _otpSent = false),
                              child: const Text('Change phone number', style: TextStyle(color: Color(0xFF4F46E5))),
                            ),
                          ),
                        ],
                        if (!_otpSent) ...[
                          const SizedBox(height: 24),
                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // WhatsApp Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6366F1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.chat, color: Color(0xFF25D366)), // WhatsApp-ish green
                              label: const Text(
                                'Continue with WhatsApp',
                                style: TextStyle(color: Color(0xFF6366F1), fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                        
                      ],
                    ),
                  ),
                  // Terms and disclaimer at bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 16),
                    child: Text.rich(
                      TextSpan(
                        text: 'By clicking above you agree to ',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        children: const [
                          TextSpan(
                            text: 'terms and conditions',
                            style: TextStyle(color: Color(0xFF6366F1), decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.identifier,
    required this.password,
    required this.busy,
    required this.error,
    required this.onLogin,
  });

  final TextEditingController identifier;
  final TextEditingController password;
  final bool busy;
  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Admin & super-admin accounts use password login.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        TextField(
          controller: identifier,
          decoration: InputDecoration(
            labelText: 'Phone or email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: busy ? null : onLogin,
            child: busy
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Sign in as admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
