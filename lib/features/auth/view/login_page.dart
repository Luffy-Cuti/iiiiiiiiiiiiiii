import 'package:flutter/material.dart';
import '../../home/view/home_screen.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.bloc, super.key});

  final LoginBloc bloc;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const Color tiktokRed = Color(0xFFFF0050);
  static const Color tiktokCyan = Color(0xFF00F2EA);
  static const Color textPrimary = Color(0xFFF1F1F2);
  static const Color textSecondary = Color(0xFF8A8B8C);
  static const Color fieldBackground = Color(0xFF2F2F2F);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  String? _lastShownMessage;
  bool _hasNavigatedToHome = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      hintStyle: const TextStyle(color: textSecondary),
      prefixIcon: Icon(icon, color: textSecondary),
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor: fieldBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: tiktokRed, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: tiktokRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: tiktokRed, width: 1.3),
      ),
      errorStyle: const TextStyle(color: tiktokRed),
    );
  }

  Widget _buildGlitchLogo() {
    const textStyle = TextStyle(
      fontSize: 54,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: textPrimary,
      height: 1,
    );

    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-2, 0),
            child: Text('TikTok', style: textStyle.copyWith(color: tiktokCyan)),
          ),
          Transform.translate(
            offset: const Offset(2, 0),
            child: Text('TikTok', style: textStyle.copyWith(color: tiktokRed)),
          ),
          const Text('TikTok', style: textStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<LoginState>(
          initialData: widget.bloc.state,
          stream: widget.bloc.stream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? const LoginState();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || state.message == null) {
                return;
              }
              if (state.message == _lastShownMessage) {
                return;
              }
              _lastShownMessage = state.message;

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _hasNavigatedToHome || !state.isLoggedIn) {
                return;
              }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      _buildGlitchLogo(),
                      const SizedBox(height: 14),
                      const Text(
                        'Đăng nhập để tiếp tục khám phá video',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 34),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x221A9E55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x5533D17A)),
                        ),
                        child: const Text(
                          'Tài khoản test: test@demo.com\nMật khẩu: 12345678',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (value) =>
                            widget.bloc.add(EmailChanged(value)),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Email hoặc Số điện thoại',
                          icon: Icons.person_outline,
                          errorText: state.emailError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) =>
                            widget.bloc.add(PasswordChanged(value)),
                        obscureText: state.obscurePassword,
                        style: const TextStyle(color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Mật khẩu',
                          icon: Icons.lock_outline,
                          errorText: state.passwordError,
                          suffix: IconButton(
                            onPressed: () => widget.bloc.add(
                              const PasswordVisibilityToggled(),
                            ),
                            icon: Icon(
                              state.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: state.rememberMe,
                            onChanged: (value) => widget.bloc.add(
                              RememberMeChanged(value ?? false),
                            ),
                            activeColor: tiktokRed,
                            side: const BorderSide(color: textSecondary),
                          ),
                          const Text(
                            'Ghi nhớ đăng nhập',
                            style: TextStyle(color: textSecondary),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: tiktokRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () => widget.bloc.add(const LoginSubmitted()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tiktokRed,
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: textPrimary,
                                  ),
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            widget.bloc.add(const GoogleLoginTapped()),
                        icon: const Icon(Icons.g_mobiledata, size: 26),
                        label: const Text(
                          'Tiếp tục với Google',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: const BorderSide(color: Color(0xFF3D3D3D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(color: textSecondary),
                          ),
                          Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: tiktokRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bằng cách tiếp tục, bạn đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư của chúng tôi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
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
