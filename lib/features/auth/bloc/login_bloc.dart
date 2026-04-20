import 'dart:async';
import 'dart:async';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc {
  LoginBloc() {
    _eventController.stream.listen(_handleEvent);
  }

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
            emailOrPhone: event.value,
            clearEmailError: true,
            clearMessage: true,
          ),
        );
      case PasswordChanged():
        _emit(
          _state.copyWith(
            password: event.value,
            clearPasswordError: true,
            clearMessage: true,
          ),
        );
      case RememberMeChanged():
        _emit(_state.copyWith(rememberMe: event.value));
      case PasswordVisibilityToggled():
        _emit(_state.copyWith(obscurePassword: !_state.obscurePassword));
      case GoogleLoginTapped():
        _emit(
          _state.copyWith(
            message:
            'Nút Google sẵn sàng UI. Cần firebase_auth + google_sign_in để hoạt động.',
          ),
        );
      case LoginSubmitted():
        await _submitLogin();
    }
  }

  Future<void> _submitLogin() async {
    final String? emailError = _validateEmailOrPhone(_state.emailOrPhone);
    final String? passwordError = _validatePassword(_state.password);

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

    _emit(
      _state.copyWith(
        isLoading: true,
        clearEmailError: true,
        clearPasswordError: true,
        clearMessage: true,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    _emit(
      _state.copyWith(
        isLoading: false,
        message:
        'Đăng nhập thành công (mock). Hãy tích hợp Firebase Auth để dùng thật.',
      ),
    );
  }

  String? _validateEmailOrPhone(String value) {
    final input = value.trim();

    if (input.isEmpty) {
      return 'Vui lòng nhập email hoặc số điện thoại';
    }

    final bool isPhone = RegExp(r'^\d+$').hasMatch(input);
    final bool isEmail = input.contains('@');

    if (!isPhone && !isEmail) {
      return 'Email phải chứa @ hoặc nhập số điện thoại hợp lệ';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 8) {
      return 'Mật khẩu phải tối thiểu 8 ký tự';
    }

    return null;
  }

  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}