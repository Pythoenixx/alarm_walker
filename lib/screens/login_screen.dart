import 'dart:async';

import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/profile_category_sync_service.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final UserProfileRepository userRepo;
  const LoginScreen({super.key, required this.userRepo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Login succeeded but user is null');
      }

      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!snap.exists) {
        throw Exception('User profile not found in Firestore');
      }

      final data = snap.data()!;
      final localProfile = await widget.userRepo.getLocalProfile();
      final syncedCategory = await ProfileCategorySyncService.syncOrBackfill(
        userId: user.uid,
        localCategory:
            localProfile?.profileCategory ?? ProfileCategory.fallback,
        cloudData: data,
      );

      unawaited(
        ProfileCategorySyncService.syncAccountEmail(
          userId: user.uid,
          email: user.email,
          cloudData: data,
        ),
      );

      final profile = UserProfile(
        userId: user.uid,
        name: data['name'],
        language: data['language'],
        theme: data['theme'] ?? 'system',
        profileCategory: syncedCategory,
      );

      await widget.userRepo.upsertLocalProfile(profile);

      if (mounted) {
        await context.read<ProfileCubit>().loadProfile(user.uid);
        await context.read<AlarmCubit>().reloadForCurrentOwner();
      }

      // Check if email is verified
      // if (userCredential.user != null && !userCredential.user!.emailVerified) {
      //   if (mounted) {
      //     setState(() => _isLoading = false);

      //     // Show verification dialog
      //     final resend = await showDialog<bool>(
      //       context: context,
      //       builder:
      //           (context) => AlertDialog(
      //             title: const Text('Email Not Verified'),
      //             content: const Text(
      //               'Please verify your email address before logging in. '
      //               'Would you like us to resend the verification email?',
      //             ),
      //             actions: [
      //               TextButton(
      //                 onPressed: () => Navigator.pop(context, false),
      //                 child: const Text('Cancel'),
      //               ),
      //               TextButton(
      //                 onPressed: () => Navigator.pop(context, true),
      //                 child: const Text('Resend'),
      //               ),
      //             ],
      //           ),
      //     );

      //     if (resend == true) {
      //       await userCredential.user!.sendEmailVerification();
      //       if (mounted) {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(
      //             content: Text('Verification email sent!'),
      //             backgroundColor: Colors.green,
      //           ),
      //         );
      //       }
      //     }

      //     // Sign out the user
      //     await FirebaseAuth.instance.signOut();
      //   }
      //   return;
      // }

      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to home screen - replace with your home route
        // Navigator.pushReplacementNamed(context, '/home');
        context.goNamed(AppRoute.home.name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } catch (error, stackTrace) {
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'auth_flow',
          screen: 'LoginScreen',
          fatal: false,
        ),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        unawaited(
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Password Reset'),
                  content: Text(
                    'A password reset link has been sent to $email. '
                    'Please check your email.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Failed to send reset email. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightScaffold1, AppColors.lightScaffold2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.login_rounded, size: 80, color: textColor),
                  const SizedBox(height: 24),
                  Text(
                    'Log In',
                    style: AppTextStyles.large(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to sync and track your progress',
                    style: AppTextStyles.caption(context),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  /// LOGIN CARD
                  _AuthCard(
                    title: '',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _InputField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            isDark: isDark,
                            suffixIcon: IconButton(
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Row(
                              //   children: [
                              //     Text(
                              //       "No account yet? ",
                              //       style: AppTextStyles.caption(context),
                              //     ),
                              //     GestureDetector(
                              //       onTap:
                              //           () => context.goNamed(
                              //             AppRoute.signUp.name,
                              //           ),
                              //       child: Text(
                              //         'Sign up',
                              //         style: AppTextStyles.caption(
                              //           context,
                              //         ).copyWith(fontWeight: FontWeight.bold),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              TextButton(
                                onPressed:
                                    () => context.goNamed(AppRoute.signUp.name),
                                child: Text(
                                  'Not yet Sign Up?',
                                  style: AppTextStyles.caption(context),
                                ),
                              ),
                              TextButton(
                                onPressed: _resetPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.caption(context),
                                ),
                              ),
                            ],
                          ),

                          // Error message with fixed space
                          SizedBox(
                            height: _errorMessage != null ? null : 0,
                            child:
                                _errorMessage != null
                                    ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Log in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// OR DIVIDER
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// GUEST CARD (IMPORTANT CHANGE)
                  _AuthCard(
                    title: 'Continue without an account',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Use the app without signing in.\nYour data stays on this device.',
                          style: AppTextStyles.caption(context),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => context.goNamed(AppRoute.home.name),
                          child: const Text('Continue as guest'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    required this.isDark,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color:
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText,
          ),

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                isDark
                    ? AppColors.darkScaffold1.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AuthCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGradient1 : AppColors.lightContainer1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
