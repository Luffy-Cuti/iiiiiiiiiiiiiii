class LoginState {
  const LoginState({
    this.emailOrPhone = '',
    this.password = '',
    this.rememberMe = true,
    this.obscurePassword = true,
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.message,
  });

  final String emailOrPhone;
  final String password;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final String? message;

  LoginState copyWith({
    String? emailOrPhone,
    String? password,
    bool? rememberMe,
    bool? obscurePassword,
    bool? isLoading,
    String? emailError,
    String? passwordError,
    String? message,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearMessage = false,
  }) {
    return LoginState(
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      passwordError: clearPasswordError
          ? null
          : passwordError ?? this.passwordError,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
