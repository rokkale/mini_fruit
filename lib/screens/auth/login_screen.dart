import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Đăng nhập thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền ảnh
          Image.network(
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6'
            '?q=80&w=2000&auto=format&fit=crop',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.45),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryDark),
          ),

          // Form đăng nhập
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceXxl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 52),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Text(
                    'MiniFruit',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hệ thống quản lý cửa hàng',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXxl),

                  // Card kính mờ
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: AppTheme.roundedXl,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceXl),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: AppTheme.roundedXl,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: AppTheme.titleLarge.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: AppTheme.spaceXs),
                                Text(
                                  'Nhập thông tin tài khoản của bạn',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceLg),

                                // Tên đăng nhập
                                _GlassField(
                                  controller: _usernameController,
                                  hint: 'Tên đăng nhập',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                                ),
                                const SizedBox(height: AppTheme.spaceMd),

                                // Mật khẩu
                                _GlassField(
                                  controller: _passwordController,
                                  hint: 'Mật khẩu',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                                  onFieldSubmitted: (_) => _login(),
                                ),
                                const SizedBox(height: AppTheme.spaceXl),

                                // Nút đăng nhập
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: AppTheme.roundedMd,
                                          ),
                                        ),
                                        child: auth.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'Đăng nhập',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget input tái sử dụng trong màn hình login (glass style)
class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Colors.white.withValues(alpha: 0.35));
    final focusedBorder = const BorderSide(color: Colors.white, width: 1.5);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedSm,
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedSm,
          borderSide: focusedBorder,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedSm,
          borderSide: BorderSide(color: Colors.orange.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedSm,
          borderSide: BorderSide(color: Colors.orange.shade300, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.orange.shade300, fontSize: 11),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
