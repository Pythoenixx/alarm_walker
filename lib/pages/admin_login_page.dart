import 'dart:async';

import 'package:alarm_walker/services/admin_auth_service.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminLoginPage extends StatefulWidget {
  final AdminAuthService authService;

  const AdminLoginPage({super.key, required this.authService});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _authMessage(error.code);
      });
    } catch (error, stackTrace) {
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'admin_login',
          screen: 'AdminLoginPage',
          fatal: false,
        ),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to complete admin login. Please try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() {
        _successMessage = null;
        _errorMessage = 'Enter a valid admin email before resetting password.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _successMessage = 'Password reset email sent to $email.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _authMessage(error.code);
      });
    }
  }

  String _authMessage(String code) {
    return switch (code) {
      'invalid-email' => 'The email address is not valid.',
      'invalid-credential' => 'Invalid admin email or password.',
      'user-not-found' => 'No admin account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many failed attempts. Try again later.',
      _ => 'Admin login failed. Please try again.',
    };
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter admin email';
    if (!_emailRegex.hasMatch(text)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter admin password';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AdminLoginHeader(theme: theme),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: _fieldDecoration(
                            context,
                            label: 'Admin Email',
                            hint: 'Enter admin email',
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _isLoading ? null : _login(),
                          decoration: _fieldDecoration(
                            context,
                            label: 'Password',
                            hint: 'Enter admin password',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              tooltip:
                                  _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          _AdminMessageBox(
                            message: _errorMessage!,
                            icon: Icons.error_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_successMessage != null) ...[
                          _AdminMessageBox(
                            message: _successMessage!,
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _login,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.login_rounded),
                            label: Text(_isLoading ? 'Logging in...' : 'Log in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _AdminLoginHeader extends StatelessWidget {
  final ThemeData theme;

  const _AdminLoginHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Admin Login',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Authorized administrators only. Sign in to manage users, reports, issues, and support tickets.',
          style: AppTextStyles.caption(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AdminMessageBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _AdminMessageBox({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}


final _emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
