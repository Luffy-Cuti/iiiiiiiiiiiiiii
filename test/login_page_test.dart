import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iiiiiiiiii/features/auth/bloc/login_bloc.dart';
import 'package:iiiiiiiiii/features/auth/models/auth_user.dart';
import 'package:iiiiiiiiii/features/auth/repository/auth_repository.dart';
import 'package:iiiiiiiiii/features/auth/view/login_page.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<void> registerWithEmailAndPassword({required String email, required String password}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> sendPhoneOtp({required String phoneNumber, required void Function(String verificationId, int? resendToken) onCodeSent, required void Function(String verificationId) onAutoVerificationTimeout, required void Function() onVerificationCompleted, required void Function(String message) onVerificationFailed}) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {}

  @override
  Future<void> signInWithGoogle({bool silent = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> verifyPhoneOtp({required String verificationId, required String smsCode}) async {}
}

void main() {
  testWidgets('LoginPage renders login button', (tester) async {
    final bloc = LoginBloc(authRepository: FakeAuthRepository());

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(bloc: bloc)),
    );

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}