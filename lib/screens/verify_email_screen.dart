import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _checking = false;
  String? _info;

  @override
  void initState() {
    super.initState();
    // Poll every few seconds so the app moves on once the link is clicked.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) context.read<AuthProvider>().checkVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _info = null;
    });
    final ok = await context.read<AuthProvider>().checkVerified();
    if (mounted) {
      setState(() {
        _checking = false;
        if (!ok) _info = 'Not verified yet. Open the link in your email first.';
      });
    }
  }

  Future<void> _resend() async {
    final err = await context.read<AuthProvider>().resendVerification();
    if (mounted) {
      setState(() => _info = err ?? 'Verification email sent again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Verify your email',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              Text(
                'We sent a verification link to\n${auth.email ?? ''}\n'
                'Open it, then come back here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              if (_info != null) ...[
                const SizedBox(height: 14),
                Text(_info!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.primaryDark, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _checking ? null : _check,
                child: _checking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text("I've verified my email"),
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: _resend, child: const Text('Resend email')),
              TextButton(
                  onPressed: auth.signOut,
                  child: const Text('Use a different account')),
            ],
          ),
        ),
      ),
    );
  }
}
