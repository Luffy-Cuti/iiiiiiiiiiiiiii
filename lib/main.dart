import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/bloc/login_bloc.dart';
import 'features/auth/repository/firebase_auth_repository.dart';
import 'features/home/repository/video_repository.dart';
import 'features/shell/app_shell.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/notification_service.dart';
import 'features/home/bloc/video_bloc.dart';

import 'features/upload/bloc/upload_bloc.dart';

import 'features/upload/repository/upload_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  await NotificationService.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = FirebaseAuthRepository();
    final videoRepository = VideoRepository();
    final uploadRepository = UploadRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => VideoBloc(videoRepository: videoRepository),
        ),
        BlocProvider(
          create: (_) => UploadVideoBloc(
            uploadRepository: uploadRepository,
            videoRepository: videoRepository,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appTitle,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: AppShell(
          authRepository: authRepository,
          loginBlocFactory: () => LoginBloc(authRepository: authRepository),
        ),
      ),
    );
  }
}
