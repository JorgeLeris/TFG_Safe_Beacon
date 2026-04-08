import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/notification_service.dart';
import 'package:safe_beacon/presentation/features/auth/routes/auth_routes.dart';
import 'package:safe_beacon/presentation/features/control/routes/control_routes.dart';
import 'package:safe_beacon/presentation/features/home/routes/home_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuth());
  }

  Future<void> _handleAuth() async {
    final l10n = context.l10n;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      if (mounted) const AuthRoute().go(context);
      return;
    }

    final pendingAlertId = NotificationService.consumeInitialAlertId();

    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (!canCheckBiometrics && !isDeviceSupported) {
      if (mounted) {
        const HomeRoute().go(context);
        if (pendingAlertId != null && pendingAlertId.isNotEmpty) {
          await AlertDetailRoute(alertId: pendingAlertId).push(context);
        }
      }
      return;
    }

    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: l10n.biometricReason,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: l10n.biometricSignInTitle,
            cancelButton: l10n.cancel,
          ),
          IOSAuthMessages(
            cancelButton: l10n.cancel,
            localizedFallbackTitle: l10n.biometricFallbackTitle,
          ),
        ],
      );

      if (!mounted) return;

      if (authenticated) {
        const HomeRoute().go(context);
        if (pendingAlertId != null && pendingAlertId.isNotEmpty) {
          await AlertDetailRoute(alertId: pendingAlertId).push(context);
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) const AuthRoute().go(context);
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) const AuthRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text(l10n.loading),
          ],
        ),
      ),
    );
  }
}
