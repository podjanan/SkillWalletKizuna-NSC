import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/providers/user_provider.dart';
import 'package:skill_wallet_kizuna/services/api_service.dart';
import 'package:skill_wallet_kizuna/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import 'welcome_screen.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

enum _AuthMode { login, register }

const _pillShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);
const _socialBorderColor = Color(0xFF4A4A4A);

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(20),
      painter: _GoogleMarkPainter(),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt;
    const sweep = 1.35;
    canvas.drawArc(
        rect, -0.25, sweep, false, paint..color = const Color(0xFF4285F4));
    canvas.drawArc(
        rect, 1.10, sweep, false, paint..color = const Color(0xFF34A853));
    canvas.drawArc(
        rect, 2.45, sweep, false, paint..color = const Color(0xFFFBBC05));
    canvas.drawArc(
        rect, 3.80, sweep, false, paint..color = const Color(0xFFEA4335));
    canvas.drawLine(
      Offset(size.width * .53, size.height * .52),
      Offset(size.width - 1.5, size.height * .52),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  _AuthMode _mode = _AuthMode.login;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _privacyPolicyUrl =
      'https://krxton.github.io/Skill-Wallet-Kizuna/privacy-policy.html';
  static const _termsOfServiceUrl =
      'https://krxton.github.io/Skill-Wallet-Kizuna/terms-of-service.html';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRegister = _mode == _AuthMode.register;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isRegister ? 44 : 50),
                    Text(
                      isRegister ? 'New to the family?' : 'Welcome Back',
                      textAlign: TextAlign.left,
                      style: AppTextStyles.heading(
                        28,
                        color: Palette.terracotta,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRegister
                          ? 'Create your account and start earning\nrewards!'
                          : 'Sign in and keep the fun going!',
                      textAlign: TextAlign.left,
                      style: AppTextStyles.body(
                        14,
                        color: Palette.authGrey,
                      ),
                    ),
                    SizedBox(height: isRegister ? 28 : 30),
                    _fieldLabel('Email'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Ex: abc@example.com',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.email_enterEmail
                          : null,
                    ),
                    SizedBox(height: isRegister ? 24 : 22),
                    if (isRegister) ...[
                      _fieldLabel('Your Name'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Ex. Saul Ramirez',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.email_enterName
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _fieldLabel('Your Password'),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '•••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.email_enterPassword;
                        }
                        if (v.length < 8) {
                          return l10n.email_passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    if (isRegister) ...[
                      const SizedBox(height: 20),
                      _fieldLabel('Confirm Password'),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: '•••••••••',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Palette.authGrey,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.email_enterPassword;
                          }
                          if (value != _passwordController.text) {
                            return l10n.email_passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(l10n),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading || !_agreedToTerms ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.terracotta,
                          elevation: 0,
                          shape: _pillShape,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isRegister ? 'Join Us!!' : 'Log In',
                                style: AppTextStyles.heading(
                                  17,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    if (!isRegister) ...[
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFF817D89)),
                      const SizedBox(height: 24),
                      _socialButton(
                        icon: const _GoogleMark(),
                        label: l10n.common_continueGoogle,
                        provider: 'google',
                      ),
                      const SizedBox(height: 12),
                      _socialButton(
                        icon: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Palette.facebook,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.facebook,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        label: l10n.common_continueFacebook,
                        provider: 'facebook',
                      ),
                    ],
                    SizedBox(height: isRegister ? 48 : 32),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _mode =
                              isRegister ? _AuthMode.login : _AuthMode.register;
                          _formKey.currentState?.reset();
                        }),
                        child: Text.rich(
                          TextSpan(
                            style: AppTextStyles.body(
                              14,
                              color: Palette.authGrey,
                            ),
                            children: [
                              TextSpan(
                                text: isRegister
                                    ? 'Already part of the family?  '
                                    : 'New to the family?  ',
                              ),
                              TextSpan(
                                text: isRegister ? 'Login' : 'Join Us',
                                style: AppTextStyles.body(
                                  14,
                                  color: Palette.terracotta,
                                  weight: FontWeight.w800,
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTextStyles.body(14, color: Palette.authGrey),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    const radius = 14.0;
    return ColoredBox(
      color: Colors.white,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        autocorrect: !obscure,
        enableSuggestions: !obscure,
        autofillHints: const <String>[],
        validator: validator,
        style: AppTextStyles.body(16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body(16, color: Colors.black38),
          prefixIcon: Icon(icon, color: Palette.terracotta, size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Palette.terracotta),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Palette.terracotta),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Palette.terracotta, width: 2),
          ),
          errorStyle: AppTextStyles.body(12),
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget icon,
    required String label,
    required String provider,
  }) {
    return Opacity(
      opacity: _agreedToTerms ? 1 : .45,
      child: SizedBox(
        height: 49,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _agreedToTerms
              ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WelcomeScreen(
                        autoProvider: provider,
                        initiallyAgreedToTerms: true,
                      ),
                    ),
                  )
              : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            side: const BorderSide(color: _socialBorderColor, width: 1),
            shape: _pillShape,
            padding: const EdgeInsets.symmetric(horizontal: 22),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(alignment: Alignment.centerLeft, child: icon),
              Text(
                label,
                style: AppTextStyles.heading(14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: Palette.terracotta,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.body(14, color: Colors.black87),
              children: [
                TextSpan(text: l10n.auth_termsAgree),
                const TextSpan(text: ' '),
                TextSpan(
                  text: l10n.auth_termsOfService,
                  style: AppTextStyles.body(14, color: Palette.terracotta)
                      .copyWith(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openUrl(_termsOfServiceUrl),
                ),
                TextSpan(text: ' ${l10n.auth_and} '),
                TextSpan(
                  text: l10n.auth_privacyPolicy,
                  style: AppTextStyles.body(14, color: Palette.terracotta)
                      .copyWith(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openUrl(_privacyPolicyUrl),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      _showMessage(AppLocalizations.of(context)!.auth_pleaseAgreeTerms);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      if (_mode == _AuthMode.login) {
        final user = await AuthService().signInWithEmail(email, password);
        await _handlePostAuth(
          userId: user.id,
          email: user.email,
          fullName: user.name.isNotEmpty ? user.name : email.split('@')[0],
        );
      } else {
        final name = _nameController.text.trim();
        final nameToUse = name.isNotEmpty ? name : email.split('@')[0];
        final user =
            await AuthService().signUpWithEmail(email, password, nameToUse);
        await _handlePostAuth(
          userId: user.id,
          email: user.email,
          fullName: nameToUse,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handlePostAuth({
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final hasAccount = await _checkParentExists();

    if (hasAccount) {
      // Existing user → sync email only (preserve user-edited name in DB)
      await _syncUserData(email: email);
      // Load photo from user metadata
      if (mounted) {
        await context.read<UserProvider>().fetchParentData();
      }
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.authenticatedHome,
          (route) => false,
        );
      }
    } else {
      await _saveUserToDatabase(
        userId: userId,
        email: email,
        fullName: fullName,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.authenticatedHome,
          (route) => false,
        );
      }
    }
  }

  Future<bool> _checkParentExists() async {
    try {
      // GET /parents/me returns 200 if parent row exists, throws on 404
      await ApiService().get('/parents/me');
      return true;
    } catch (e) {
      debugPrint('Check parent error: $e');
      return false;
    }
  }

  Future<void> _syncUserData({required String? email}) async {
    try {
      final apiService = ApiService();
      // Only pass email — do NOT pass fullName so the user's manually edited
      // name in the DB is preserved across logins.
      final result = await apiService.post('/parents/sync', {
        'email': email,
      });
      final parentName = result['parent']?['nameSurname'] as String?;
      final parentId = result['parent']?['parentId']?.toString();
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        if (parentName != null && parentName.isNotEmpty) {
          userProvider.setParentName(parentName);
        }
        if (parentId != null) userProvider.setParentId(parentId);
        unawaited(userProvider.fetchChildrenData());
      }
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  Future<void> _saveUserToDatabase({
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final String nameToSave = fullName ?? email?.split('@')[0] ?? 'User';
    try {
      final apiService = ApiService();
      final result = await apiService.post('/parents/sync', {
        'email': email,
        'fullName': nameToSave,
      });
      final parentName = result['parent']?['nameSurname'] ?? nameToSave;
      if (mounted) {
        context.read<UserProvider>().setParentName(parentName);
      }
      debugPrint('User saved via API: $parentName');
    } catch (e) {
      debugPrint('Error saving user to database: $e');
    }
  }

  // TODO: Forgot password — not yet implemented (requires email provider setup e.g. Resend/Nodemailer)
  // Future<void> _showForgotPasswordDialog() async {
  //   final l10n = AppLocalizations.of(context)!;
  //   final emailController = TextEditingController(
  //     text: _emailController.text.trim(),
  //   );
  //
  //   await showDialog<void>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Text(l10n.email_forgotTitle,
  //           style: AppTextStyles.body(18, weight: FontWeight.bold)),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(l10n.email_forgotMsg, style: AppTextStyles.body(14)),
  //           const SizedBox(height: 12),
  //           TextField(
  //             controller: emailController,
  //             keyboardType: TextInputType.emailAddress,
  //             style: AppTextStyles.body(15),
  //             decoration: InputDecoration(
  //               hintText: l10n.email_emailHint,
  //               hintStyle: AppTextStyles.body(15, color: Colors.black38),
  //               border:
  //                   OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx),
  //           child: Text(l10n.common_cancel,
  //               style: AppTextStyles.body(14, color: Colors.black54)),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
  //           onPressed: () async {
  //             final email = emailController.text.trim();
  //             if (email.isEmpty) return;
  //             Navigator.pop(ctx);
  //             try {
  //               await AuthService().forgotPassword(email);
  //               if (mounted) _showMessage(l10n.email_resetSent);
  //             } catch (e) {
  //               if (mounted) _showMessage(e.toString().replaceFirst('Exception: ', ''));
  //             }
  //           },
  //           child: Text(l10n.email_sendReset,
  //               style: AppTextStyles.body(14, color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   emailController.dispose();
  // }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
