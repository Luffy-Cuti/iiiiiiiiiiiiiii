class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.rememberMe = true,
    this.obscurePassword = true,
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.message,
    this.isLoggedIn = false,
    this.passwordStrength = 0,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? message;
  final bool isLoggedIn;
  final double passwordStrength;

  LoginState copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? obscurePassword,
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? message,
    bool? isLoggedIn,
    double? passwordStrength,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearMessage = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      passwordError: clearPasswordError
          ? null
          : passwordError ?? this.passwordError,
      message: clearMessage ? null : message ?? this.message,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      passwordStrength: passwordStrength ?? this.passwordStrength,
    );
  }
}
