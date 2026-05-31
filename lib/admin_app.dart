import 'package:alarm_walker/layout/admin_layout.dart';
import 'package:alarm_walker/screens/admin_login_screen.dart';
import 'package:alarm_walker/services/admin_auth_service.dart';
import 'package:alarm_walker/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AdminAuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  final _authService = AdminAuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && user == null) {
          return const _AdminLoadingScreen(message: 'Checking admin session...');
        }

        if (user == null) {
          return AdminLoginScreen(authService: _authService);
        }

        return FutureBuilder<bool>(
          future: _authService.isAuthorizedAdmin(user),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState != ConnectionState.done) {
              return const _AdminLoadingScreen(
                message: 'Verifying admin access...',
              );
            }

            if (adminSnapshot.hasError) {
              return _AdminAccessProblemScreen(
                title: 'Unable to verify admin access',
                message:
                    'The panel could not check your admin permission. Please review Firestore rules or try again.',
                onSignOut: _authService.signOut,
              );
            }

            if (adminSnapshot.data == true) {
              return AdminLayout(
                adminEmail: user.email ?? 'Admin',
                onLogout: _authService.signOut,
              );
            }

            return _AdminAccessProblemScreen(
              title: 'Access denied',
              message:
                  'This signed-in account is not marked as an admin. Use an authorized admin account to continue.',
              onSignOut: _authService.signOut,
            );
          },
        );
      },
    );
  }
}

class _AdminLoadingScreen extends StatelessWidget {
  final String message;

  const _AdminLoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _AdminAccessProblemScreen extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onSignOut;

  const _AdminAccessProblemScreen({
    required this.title,
    required this.message,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => onSignOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Back to admin login'),
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
