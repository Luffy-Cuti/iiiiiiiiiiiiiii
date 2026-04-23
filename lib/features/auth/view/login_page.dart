import 'package:flutter/material.dart';
import '../../home/view/home_screen.dart';
import 'dart:io';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/view/home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.bloc, super.key});

  final LoginBloc bloc;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const Duration animationDuration = Duration(milliseconds: 900);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  String? _lastShownMessage;
  bool _hasNavigatedToHome = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curvedAnimation);
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    widget.bloc.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<LoginState>(
          initialData: widget.bloc.state,
          stream: widget.bloc.stream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? const LoginState();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || state.message == null) return;
              if (state.message == _lastShownMessage) return;
              _lastShownMessage = state.message;

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.message!)),
                      ],
                    ),
                  ),
                );
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _hasNavigatedToHome || !state.isLoggedIn) return;

              _hasNavigatedToHome = true;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            });

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        AppStrings.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.hint,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        enabled: !state.isLoading,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) =>
                            widget.bloc.add(EmailChanged(value)),
                        onEditingComplete: () {
                          widget.bloc.add(EmailChanged(_emailController.text));
                          FocusScope.of(context).requestFocus(_passwordFocus);
                        },
                        style: AppTextStyles.body,
                        decoration: _inputDecoration(
                          hint: AppStrings.emailHint,
                          icon: Icons.email_outlined,
                          errorText: state.emailError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        enabled: !state.isLoading,
                        textInputAction: TextInputAction.done,
                        obscureText: state.obscurePassword,
                        onChanged: (value) =>
                            widget.bloc.add(PasswordChanged(value)),
                        onEditingComplete: () =>
                            widget.bloc.add(const LoginSubmitted()),
                        style: AppTextStyles.body,
                        decoration: _inputDecoration(
                          hint: AppStrings.passwordHint,
                          icon: Icons.lock_outline,
                          errorText: state.passwordError,
                          suffix: IconButton(
                            onPressed: state.isLoading
                                ? null
                                : () => widget.bloc.add(
                                    const PasswordVisibilityToggled(),
                                  ),
                            icon: Icon(
                              state.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.passwordStrength,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: state.passwordStrength >= 0.75
                            ? Colors.green
                            : Colors.orange,
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: state.rememberMe,
                            onChanged: state.isLoading
                                ? null
                                : (value) => widget.bloc.add(
                                    RememberMeChanged(value ?? false),
                                  ),
                          ),
                          const Text(
                            'Ghi nhớ đăng nhập',
                            style: AppTextStyles.hint,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => widget.bloc.add(
                                    const ForgotPasswordSubmitted(),
                                  ),
                            child: const Text(AppStrings.forgotPassword),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () => widget.bloc.add(const LoginSubmitted()),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  AppStrings.login,
                                  style: AppTextStyles.button,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => widget.bloc.add(const GoogleLoginTapped()),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text(AppStrings.googleSignIn),
                      ),
                      if (Platform.isIOS || Platform.isMacOS)
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => widget.bloc.add(const AppleLoginTapped()),
                          icon: const Icon(Icons.apple),
                          label: const Text(AppStrings.appleSignIn),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () => widget.bloc.add(const RegisterSubmitted()),
                        child: const Text('Đăng ký tài khoản mới'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
