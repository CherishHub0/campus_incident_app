import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _error = null);
    final err = _isLogin
        ? await auth.signIn(_email.text, _password.text)
        : await auth.register(_name.text, _email.text, _password.text);
    if (mounted && err != null) setState(() => _error = err);
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your ALU email above first.');
      return;
    }

    setState(() => _error = null);
    final error = await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'If an account exists, password reset instructions were sent.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Welcome back 👋' : 'Create your account',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Students use @alustudent.com; staff use @alueducation.com.'
                      : 'Use @alustudent.com as a student or @alueducation.com as staff. We will send a verification link.',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                if (!_isLogin) ...[
                  _label('Full name'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Amina Hassan'),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                _label('ALU email'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'name@alustudent.com',
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (!t.contains('@')) return 'Enter a valid email';
                    if (!_isLogin && !isAllowedEmail(t)) {
                      return 'Only ${allowedEmailDomains.map((d) => '@$d').join(' / ')} emails are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : _sendPasswordReset,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.redBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.redFg,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.redFg,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Sign in' : 'Create account'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          }),
                    child: Text(
                      _isLogin
                          ? "New here? Create an account"
                          : 'Already have an account? Sign in',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
  );
}
