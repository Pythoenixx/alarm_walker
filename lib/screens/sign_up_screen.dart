import 'dart:async';

import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  ProfileCategory _selectedCategory = ProfileCategory.fallback;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCategory = _selectedCategory;
    final profileCubit = context.read<ProfileCubit>();
    final settingsCubit = context.read<SettingsCubit>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final profile = UserProfile(
        userId: user.uid,
        name: _nameController.text.trim(),
        language: 'en',
        theme: 'system',
        profileCategory: selectedCategory,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'userId': profile.userId,
        'name': profile.name,
        'email': user.email ?? _emailController.text.trim(),
        'language': profile.language,
        'theme': profile.theme,
        'profileCategory': profile.profileCategory.name,
      });

      await profileCubit.updateProfile(profile);
      await settingsCubit.applyProfileCategoryDefaults(selectedCategory);

      if (mounted) {
        setState(() => _isLoading = false);

        unawaited(
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              final isDark = context.isDarkMode;
              return AlertDialog(
                backgroundColor:
                    isDark
                        ? AppColors.darkScaffold1
                        : AppColors.lightContainer1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // UPDATED: withValues instead of withOpacity
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Account Created!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Your account has been successfully created. Welcome aboard!',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.goNamed(AppRoute.login.name);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              );
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
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
          screen: 'SignUpScreen',
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

  // Validators remain the same...
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.goNamed(AppRoute.login.name),
                      color:
                          isDark
                              ? AppColors.darkBackgroundText
                              : AppColors.lightBackgroundText,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            // UPDATED: withValues
                            color:
                                isDark
                                    ? AppColors.darkScaffold1.withValues(
                                      alpha: 0.5,
                                    )
                                    : AppColors.lightContainer1,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBlueGrey,
                            ),
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color:
                                isDark
                                    ? AppColors.darkBackgroundText
                                    : AppColors.lightBackgroundText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: AppTextStyles.large(
                            context,
                          ).copyWith(fontSize: 32, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to sync your alarms across devices',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    // UPDATED: withValues
                                    ? AppColors.darkBackgroundText.withValues(
                                      alpha: 0.7,
                                    )
                                    : AppColors.lightBackgroundText.withValues(
                                      alpha: 0.7,
                                    ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _InputField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your name',
                          prefixIcon: Icons.person_outline,
                          validator: _validateName,
                          isDark: isDark,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _ProfileCategorySelector(
                          selectedCategory: _selectedCategory,
                          onChanged:
                              (category) =>
                                  setState(() => _selectedCategory = category),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          isDark: isDark,
                          textInputAction: TextInputAction.next,
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
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          validator: _validateConfirmPassword,
                          isDark: isDark,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // UPDATED: withValues
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
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
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
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
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color:
                                    isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBlueGrey,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 12,
                                  // UPDATED: withValues
                                  color:
                                      isDark
                                          ? AppColors.darkBackgroundText
                                              .withValues(alpha: 0.5)
                                          : AppColors.lightBackgroundText
                                              .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color:
                                    isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBlueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // UPDATED: withValues
                            color:
                                isDark
                                    ? AppColors.darkScaffold1.withValues(
                                      alpha: 0.3,
                                    )
                                    : AppColors.lightContainer1.withValues(
                                      alpha: 0.5,
                                    ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBlueGrey,
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  fontSize: 14,
                                  // UPDATED: withValues
                                  color:
                                      isDark
                                          ? AppColors.darkBackgroundText
                                              .withValues(alpha: 0.7)
                                          : AppColors.lightBackgroundText
                                              .withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              GestureDetector(
                                onTap:
                                    () => context.goNamed(AppRoute.login.name),
                                child: Text(
                                  'Log In',
                                  style: AppTextStyles.large(context).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCategorySelector extends StatelessWidget {
  final ProfileCategory selectedCategory;
  final ValueChanged<ProfileCategory> onChanged;
  final bool isDark;

  const _ProfileCategorySelector({
    required this.selectedCategory,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a category to apply suitable default alarm difficulty.',
          style: TextStyle(
            fontSize: 12,
            color:
                isDark
                    ? AppColors.darkBackgroundText.withValues(alpha: 0.65)
                    : AppColors.lightBackgroundText.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ProfileCategory.values.map((category) {
                final isSelected = selectedCategory == category;
                return _ProfileCategoryChip(
                  category: category,
                  selected: isSelected,
                  isDark: isDark,
                  onTap: () => onChanged(category),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _ProfileCategoryChip extends StatelessWidget {
  final ProfileCategory category;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileCategoryChip({
    required this.category,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    return switch (category) {
      ProfileCategory.child => Icons.child_care_outlined,
      ProfileCategory.adult => Icons.person_outline,
      ProfileCategory.senior => Icons.accessibility_new_outlined,
    };
  }

  String get _description {
    return switch (category) {
      ProfileCategory.child => 'Easy tasks',
      ProfileCategory.adult => 'Balanced tasks',
      ProfileCategory.senior => 'Light tasks',
    };
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected
            ? Colors.white
            : isDark
            ? AppColors.darkBackgroundText
            : AppColors.lightBackgroundText;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary
                  : isDark
                  ? AppColors.darkScaffold1.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBlueGrey,
            width: selected ? 2 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: foreground, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _description,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

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
    this.textInputAction,
    this.onFieldSubmitted,
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
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
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
                    // UPDATED: withValues
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
