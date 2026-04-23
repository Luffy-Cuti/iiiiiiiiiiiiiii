import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../auth/models/auth_user.dart';
import '../auth/repository/auth_repository.dart';
import '../auth/services/auth_local_storage.dart';
import '../auth/view/login_page.dart';
import '../home/view/home_screen.dart';
import '../auth/bloc/login_bloc.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.authRepository,
    required this.loginBlocFactory,
    super.key,
  });

  final AuthRepository authRepository;
  final LoginBloc Function() loginBlocFactory;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _prepareAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        return StreamBuilder<AuthUser?>(
          stream: authRepository.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final user = authSnapshot.data;
            if (user == null) {
              return FutureBuilder<bool>(
                future: AuthLocalStorage.isFirstLaunchDone(),
                builder: (context, firstLaunchSnapshot) {
                  if (firstLaunchSnapshot.connectionState !=
                      ConnectionState.done) {
                    return const SplashScreen();
                  }

                  final isDone = firstLaunchSnapshot.data ?? false;
                  if (!isDone) {
                    return OnboardingScreen(loginBlocFactory: loginBlocFactory);
                  }
                  return LoginPage(bloc: loginBlocFactory());
                },
              );
            }
            return const HomeScreen();
          },
        );
      },
    );
  }

  Future<bool> _prepareAuth() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (await AuthLocalStorage.shouldAutoLogout()) {
      await authRepository.signOut();
      await AuthLocalStorage.clearLoginStatus();
    }
    try {
      await authRepository.signInWithGoogle(silent: true);
    } catch (_) {
      // Ignore revoked token or no previous session.
    }
    return true;
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({required this.loginBlocFactory, super.key});

  final LoginBloc Function() loginBlocFactory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(AppStrings.appTitle),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await AuthLocalStorage.markFirstLaunchDone();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => LoginPage(bloc: loginBlocFactory()),
                    ),
                  );
                }
              },
              child: const Text('Bắt đầu'),
            ),
          ],
        ),
      ),
    );
  }
}
