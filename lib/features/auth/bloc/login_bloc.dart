import 'dart:async';
import 'dart:async';
import '../repository/firebase_auth_repository.dart';
import '../services/auth_local_storage.dart';

import 'login_event.dart';
import 'login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../repository/auth_repository.dart';
import '../services/auth_local_storage.dart';

class LoginBloc {
  LoginBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository() {
    _eventController.stream.listen(_handleEvent);
  }

  final AuthRepository _authRepository;
  final StreamController<LoginEvent> _eventController =
      StreamController<LoginEvent>();
  final StreamController<LoginState> _stateController =
      StreamController<LoginState>.broadcast();

  LoginState _state = const LoginState();

  Stream<LoginState> get stream => _stateController.stream;

  LoginState get state => _state;

  void add(LoginEvent event) {
    _eventController.add(event);
  }

  void _emit(LoginState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  Future<void> _handleEvent(LoginEvent event) async {
    switch (event) {
      case EmailChanged():
        _emit(
          _state.copyWith(
            email: event.value.trim().toLowerCase(),
            clearEmailError: true,
            clearMessage: true,
          ),
        );
      case PasswordChanged():
        final value = event.value;
        _emit(
          _state.copyWith(
            password: value,
            passwordStrength: _measurePasswordStrength(value),
            clearPasswordError: true,
            clearMessage: true,
          ),
        );
      case RememberMeChanged():
        _emit(_state.copyWith(rememberMe: event.value));
      case PasswordVisibilityToggled():
        _emit(_state.copyWith(obscurePassword: !_state.obscurePassword));
      case GoogleLoginTapped():
        await _submitGoogleLogin();
      case AppleLoginTapped():
        await _submitAppleLogin();
      case LoginSubmitted():
        await _submitLogin();
      case ForgotPasswordSubmitted():
        await _submitForgotPassword();
      case RegisterSubmitted():
        await _submitRegister();
    }
  }

  Future<void> _submitLogin() async {
    final emailError = _validateEmail(_state.email);
    final passwordError = _validatePassword(_state.password);

    if (emailError != null || passwordError != null) {
      _emit(
        _state.copyWith(
          emailError: emailError,
          passwordError: passwordError,
          clearMessage: true,
        ),
      );
      return;
    }
    _emit(_state.copyWith(isLoading: true, clearMessage: true));

    try {
      await _authRepository.signInWithEmailAndPassword(
        email: _state.email,
        password: _state.password,
      );
      if (_state.rememberMe) {
        await AuthLocalStorage.saveLoginStatus(isLoggedIn: true);
      }
      _emit(_state.copyWith(isLoading: false, isLoggedIn: true));
    } on FirebaseAuthException catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          message: e.message ?? AppStrings.loginFailed,
        ),
      );
    }
  }

  Future<void> _submitRegister() async {
    final emailError = _validateEmail(_state.email);
    final passwordError = _validatePassword(_state.password);
    if (emailError != null || passwordError != null) {
      _emit(
        _state.copyWith(emailError: emailError, passwordError: passwordError),
      );
      return;
    }

    _emit(_state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _authRepository.registerWithEmailAndPassword(
        email: _state.email,
        password: _state.password,
      );
      _emit(
        _state.copyWith(isLoading: false, message: AppStrings.registerSuccess),
      );
    } on FirebaseAuthException catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          message: e.message ?? AppStrings.loginFailed,
        ),
      );
    }
  }

  Future<void> _submitForgotPassword() async {
    final emailError = _validateEmail(_state.email);
    if (emailError != null) {
      _emit(_state.copyWith(emailError: emailError));
      return;
    }
    _emit(_state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _authRepository.sendPasswordResetEmail(email: _state.email);
      _emit(_state.copyWith(isLoading: false, message: AppStrings.resetSent));
    } on FirebaseAuthException catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          message: e.message ?? AppStrings.loginFailed,
        ),
      );
    }
  }

  Future<void> _submitGoogleLogin() async {
    _emit(_state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _authRepository.signInWithGoogle();
      await AuthLocalStorage.saveLoginStatus(isLoggedIn: true);
      _emit(_state.copyWith(isLoading: false, isLoggedIn: true));
    } on FirebaseAuthException catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          message: e.message ?? AppStrings.loginFailed,
        ),
      );
    }
  }

  Future<void> _submitAppleLogin() async {
    _emit(_state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _authRepository.signInWithApple();
      await AuthLocalStorage.saveLoginStatus(isLoggedIn: true);
      _emit(_state.copyWith(isLoading: false, isLoggedIn: true));
    } on FirebaseAuthException catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          message: e.message ?? AppStrings.loginFailed,
        ),
      );
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return AppStrings.requiredEmail;
    }
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (!isEmail) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return AppStrings.requiredPassword;
    }

    if (value.length < 8) {
      return AppStrings.weakPassword;
    }

    return null;
  }

  double _measurePasswordStrength(String value) {
    if (value.isEmpty) {
      return 0;
    }
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(value);

    var score = 0.0;
    if (value.length >= 8) score += 0.25;
    if (hasUppercase && hasLowercase) score += 0.25;
    if (hasDigit) score += 0.25;
    if (hasSpecial) score += 0.25;

    return score;
  }

  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}
