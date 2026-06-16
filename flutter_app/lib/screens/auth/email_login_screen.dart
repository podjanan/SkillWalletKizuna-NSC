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
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

enum _AuthMode { login, register }

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          isRegister ? l10n.email_registerTitle : l10n.email_loginTitle,
          style: AppTextStyles.heading(20, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name field (register only)
                      if (isRegister) ...[
                        _buildTextField(
                          controller: _nameController,
                          hint: l10n.email_nameHint,
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.email_enterName
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        hint: l10n.email_emailHint,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.email_enterEmail
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        hint: l10n.email_passwordHint,
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.email_enterPassword;
                          }
                          if (v.length < 6) {
                            return l10n.email_passwordTooShort;
                          }
                          return null;
                        },
                      ),

                      // Confirm password field (register only)
                      if (isRegister) ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: l10n.email_confirmPasswordHint,
                          icon: Icons.lock_outline,
                          obscure: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black54,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.email_enterPassword;
                            }
                            if (v != _passwordController.text) {
                              return l10n.email_passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Terms checkbox
                      _buildTermsCheckbox(l10n),
                      const SizedBox(height: 20),

                      // Submit button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.sky,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                isRegister
                                    ? l10n.email_registerBtn
                                    : l10n.email_loginBtn,
                                style: AppTextStyles.heading(16, color: Colors.white),
                              ),
                            ),

                      const SizedBox(height: 12),

                      // TODO: Forgot password — not yet implemented (requires email provider setup)
                      // if (!isRegister)
                      //   Center(
                      //     child: TextButton(
                      //       onPressed: _showForgotPasswordDialog,
                      //       child: Text(
                      //         l10n.email_forgotPassword,
                      //         style: AppTextStyles.body(14, color: Palette.sky),
                      //       ),
                      //     ),
                      //   ),

                      const SizedBox(height: 8),

                      // Switch mode
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() {
                            _mode = isRegister
                                ? _AuthMode.login
                                : _AuthMode.register;
                            _formKey.currentState?.reset();
                            _confirmPasswordController.clear();
                          }),
                          child: Text(
                            isRegister
                                ? l10n.email_hasAccount
                                : l10n.email_noAccount,
                            style: AppTextStyles.body(14, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: AppTextStyles.body(16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body(16, color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorStyle: AppTextStyles.body(12),
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
            activeColor: Palette.sky,
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
                  style: AppTextStyles.body(14, color: Palette.sky).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openUrl(_termsOfServiceUrl),
                ),
                TextSpan(text: ' ${l10n.auth_and} '),
                TextSpan(
                  text: l10n.auth_privacyPolicy,
                  style: AppTextStyles.body(14, color: Palette.sky).copyWith(
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
      final email = _emailController.text.trim();
      final password = _passwordController.text;

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
          AppRoutes.home,
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
          AppRoutes.home,
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
