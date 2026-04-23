import '../models/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser?> getCurrentUser();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount({required String currentPassword});

  Future<void> signInWithGoogle({bool silent = false});

  Future<void> signInWithApple();

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onAutoVerificationTimeout,
    required void Function() onVerificationCompleted,
    required void Function(String message) onVerificationFailed,
  });

  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}
