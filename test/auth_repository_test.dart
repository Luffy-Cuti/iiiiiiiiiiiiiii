import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:iiiiiiiiii/features/auth/repository/firebase_auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  group('FirebaseAuthRepository', () {
    late MockFirebaseAuth firebaseAuth;
    late MockGoogleSignIn googleSignIn;
    late FirebaseAuthRepository repository;

    setUp(() {
      firebaseAuth = MockFirebaseAuth();
      googleSignIn = MockGoogleSignIn();
      repository = FirebaseAuthRepository(
        firebaseAuth: firebaseAuth,
        googleSignIn: googleSignIn,
      );
    });

    test('signInWithEmailAndPassword throws when email not verified', () async {
      final credential = MockUserCredential();
      final user = MockUser();

      when(firebaseAuth.signInWithEmailAndPassword(
        email: 'demo@site.com',
        password: 'password123',
      )).thenAnswer((_) async => credential);
      when(credential.user).thenReturn(user);
      when(user.emailVerified).thenReturn(false);
      when(firebaseAuth.signOut()).thenAnswer((_) async {});

      expect(
            () => repository.signInWithEmailAndPassword(
          email: 'demo@site.com',
          password: 'password123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}