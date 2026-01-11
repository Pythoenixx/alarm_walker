import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.userRepo.getProfile(_user!.uid);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: AppTextStyles.large(context)),
                const SizedBox(height: 24),

                _ProfileCard(user: _user, profile: _profile),
                const SizedBox(height: 16),

                const _PreferencesCard(),
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
  const _ProfileCard({this.user, this.profile});

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
          const CircleAvatar(radius: 28),
          const SizedBox(width: 16),
          Column(
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
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Theme', style: AppTextStyles.body(context)),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          title: Text('Language', style: AppTextStyles.body(context)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
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
        child: const Text('Sign in to sync & backup'),
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
        context.goNamed(AppRoute.login.name);
      },
      child: const Text('Sign out'),
    );
  }
}
