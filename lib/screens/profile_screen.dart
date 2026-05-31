import 'dart:async';

import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/profile_category_sync_service.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


class ProfileScreen extends StatefulWidget {
  final UserProfileRepository userRepo;
  const ProfileScreen({super.key, required this.userRepo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;

    var profile =
        await widget.userRepo.getProfile(uid) ??
        UserProfile(
          userId: uid,
          name: _user?.displayName ?? 'User',
          language: 'en',
          theme: 'system',
          profileCategory: ProfileCategory.fallback,
        );

    final syncedCategory = await ProfileCategorySyncService.syncOrBackfill(
      userId: uid,
      localCategory: profile.profileCategory,
    );

    if (syncedCategory != profile.profileCategory) {
      profile = profile.copyWith(profileCategory: syncedCategory);
      await widget.userRepo.saveProfile(profile);
    }

    if (!mounted) return;
    setState(() => _profile = profile);
  }

  UserProfile _currentOrNewProfile() {
    final uid = _user?.uid;
    if (uid == null) {
      throw StateError('Cannot update profile because no user is signed in.');
    }

    return _profile ??
        UserProfile(
          userId: uid,
          name: _user?.displayName ?? 'User',
          language: 'en',
          theme: 'system',
          profileCategory: ProfileCategory.fallback,
        );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: _profile?.name ?? '');
    final isDark = context.isDarkMode;

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor:
              isDark ? AppColors.darkGradient1 : AppColors.lightContainer1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit name', style: AppTextStyles.heading(context)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: AppTextStyles.body(context),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed:
                          () => Navigator.pop(context, controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;

    final uid = _user?.uid;
    if (uid == null) return;

    await widget.userRepo.updateName(userId: uid, name: result);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(result);

    setState(() {
      _profile = _profile?.copyWith(name: result);
    });
  }

  Future<void> _editProfileCategory(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final isDark = context.isDarkMode;
    var selected = _profile?.profileCategory ?? ProfileCategory.fallback;

    final selectedCategory = await showDialog<ProfileCategory>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor:
                  isDark ? AppColors.darkGradient1 : AppColors.lightContainer1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile category',
                      style: AppTextStyles.heading(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the category that best fits the user. The app will apply recommended default difficulty for new alarms.',
                      style: AppTextStyles.caption(context),
                    ),
                    const SizedBox(height: 12),
                    ...ProfileCategory.values.map(
                      (category) => RadioListTile<ProfileCategory>(
                        value: category,
                        groupValue: selected,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selected = value);
                        },
                        secondary: Icon(_iconForCategory(category)),
                        title: Text(category.label),
                        subtitle: Text(_descriptionForCategory(category)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'Recommended defaults will be applied for new alarms only. Existing alarms will not be changed automatically.',
                        style: AppTextStyles.caption(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, selected),
                          child: const Text('Apply Category'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedCategory == null) return;

    final updated = _currentOrNewProfile().copyWith(
      profileCategory: selectedCategory,
    );

    await widget.userRepo.saveProfile(updated);
    final syncedToCloud = await ProfileCategorySyncService.saveCategory(
      userId: updated.userId,
      category: selectedCategory,
    );
    await settingsCubit.applyProfileCategoryDefaults(selectedCategory);

    if (!mounted) return;

    setState(() => _profile = updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          syncedToCloud
              ? '${selectedCategory.label} category saved. Recommended defaults applied for new alarms.'
              : '${selectedCategory.label} category saved locally. Cloud sync will retry when you update it again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currentCategory = _profile?.profileCategory ?? ProfileCategory.fallback;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                )
                : null,
        centerTitle: true,
        title: const Text('Profile'),
        titleTextStyle: AppTextStyles.heading(context),
      ),
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
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                _ProfileCard(
                  user: _user,
                  profile: _profile,
                  category: currentCategory,
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit name'),
                  onTap: () => _editName(context),
                ),
                ListTile(
                  leading: Icon(_iconForCategory(currentCategory)),
                  title: const Text('Profile category'),
                  subtitle: Text(
                    '${currentCategory.label} · Used for recommended new-alarm difficulty',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editProfileCategory(context),
                ),

                const Spacer(),

                _AccountActionSection(user: _user),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User? user;
  final UserProfile? profile;
  final ProfileCategory category;

  const _ProfileCard({
    this.user,
    this.profile,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? AppColors.darkGradient1
                : AppColors.lightContainer1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                context.isDarkMode
                    ? AppColors.shadowDark
                    : AppColors.shadowLight,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(
              _iconForCategory(category),
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.isAnonymous == true
                      ? 'Guest User'
                      : (profile?.name ?? 'User'),
                  style: AppTextStyles.heading(context),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.isAnonymous == true
                      ? 'Not signed in'
                      : (user?.email ?? ''),
                  style: AppTextStyles.caption(context),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    category.label,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
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

class _AccountActionSection extends StatelessWidget {
  final User? user;

  const _AccountActionSection({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null || user!.isAnonymous) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => context.goNamed(AppRoute.login.name),
        child: const Text(
          'Sign in to sync & backup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        // This satisfies the "async gap" check
        if (!context.mounted) return;

        await context.read<ProfileCubit>().loadProfile('local');
        await context.read<AlarmCubit>().reloadForCurrentOwner();

        if (!context.mounted) return;

        context.goNamed(AppRoute.login.name);
      },

      child: const Text(
        'Sign out',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
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
