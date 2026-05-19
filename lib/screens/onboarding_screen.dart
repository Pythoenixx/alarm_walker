import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/services/onboarding_service.dart';
import 'package:alarm_walker/services/profile_category_sync_service.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  ProfileCategory _selectedCategory = ProfileCategory.fallback;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    if (_saving) return;

    setState(() => _saving = true);

    final profileCubit = context.read<ProfileCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    final currentProfile =
        profileCubit.state ??
        const UserProfile(
          userId: 'local',
          name: '',
          language: 'en',
          theme: 'system',
        );

    await profileCubit.updateProfile(
      currentProfile.copyWith(profileCategory: _selectedCategory),
    );

    final signedInUser = FirebaseAuth.instance.currentUser;
    if (signedInUser != null) {
      await ProfileCategorySyncService.saveCategory(
        userId: signedInUser.uid,
        category: _selectedCategory,
      );
    }

    await settingsCubit.applyProfileCategoryDefaults(_selectedCategory);
    await OnboardingService.markCompleted();

    if (!mounted) return;

    context.goNamed(AppRoute.home.name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightScaffold1, AppColors.lightScaffold2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: [
                      const _IntroStep(),
                      _CategoryStep(
                        selectedCategory: _selectedCategory,
                        onChanged:
                            (category) => setState(
                              () => _selectedCategory = category,
                            ),
                      ),
                      const _ReadyStep(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Dots(current: _page, total: 3),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saving ? null : _next,
                    child:
                        _saving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(_page == 2 ? 'Start using app' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep();

  @override
  Widget build(BuildContext context) {
    return _OnboardingContent(
      icon: Icons.alarm,
      title: 'Welcome to Alarm Walker',
      description:
          'Create alarms that require wake-up tasks such as math, typing, shaking, or walking before they can be dismissed.',
      children: const [
        _FeatureLine(
          icon: Icons.psychology_outlined,
          text: 'Cognitive and physical disarm modes',
        ),
        _FeatureLine(
          icon: Icons.snooze,
          text: 'Controlled snooze for better wake-up habits',
        ),
        _FeatureLine(
          icon: Icons.insights,
          text: 'Wake-up analytics to track progress',
        ),
      ],
    );
  }
}

class _CategoryStep extends StatelessWidget {
  final ProfileCategory selectedCategory;
  final ValueChanged<ProfileCategory> onChanged;

  const _CategoryStep({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingContent(
      icon: Icons.tune,
      title: 'Choose your profile category',
      description:
          'Your category sets recommended default difficulty for new alarms. You can change it later in Profile.',
      children:
          ProfileCategory.values
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(
                    category: category,
                    selected: category == selectedCategory,
                    onTap: () => onChanged(category),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingContent(
      icon: Icons.rocket_launch_outlined,
      title: 'Ready to wake up smarter',
      description:
          'You can start using Alarm Walker without signing in. Sign in later if you want account features.',
      children: [
        _FeatureLine(
          icon: Icons.check_circle_outline,
          text: 'Create your first alarm',
        ),
        _FeatureLine(
          icon: Icons.settings_outlined,
          text: 'Customize sound, snooze, and disarm modes',
        ),
        _FeatureLine(
          icon: Icons.cloud_outlined,
          text: 'Weather-aware wake-up tips when enabled',
        ),
      ],
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 24),
        Text(title, style: AppTextStyles.large(context)),
        const SizedBox(height: 12),
        Text(description, style: AppTextStyles.body(context)),
        const SizedBox(height: 28),
        ...children,
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProfileCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withOpacity(0.14)
                  : context.isDarkMode
                  ? AppColors.darkGradient1
                  : AppColors.lightContainer1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(_iconForCategory(category), color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label, style: AppTextStyles.heading(context)),
                  const SizedBox(height: 4),
                  Text(
                    _descriptionForCategory(category),
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(context))),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int current;
  final int total;

  const _Dots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                active
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

IconData _iconForCategory(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => Icons.child_care,
    ProfileCategory.adult => Icons.person,
    ProfileCategory.senior => Icons.elderly,
  };
}

String _descriptionForCategory(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => 'Gentler defaults for younger users.',
    ProfileCategory.adult => 'Balanced defaults for regular use.',
    ProfileCategory.senior => 'Lighter defaults for safer wake-up tasks.',
  };
}
