import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kizuna/l10n/app_localizations.dart';
import 'package:skill_wallet_kizuna/providers/user_provider.dart';
import 'package:skill_wallet_kizuna/services/api_service.dart';
import 'package:skill_wallet_kizuna/services/auth_service.dart';
import 'package:skill_wallet_kizuna/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_wallet_kizuna/widgets/google_sign_in_button.dart';
import '../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _waitingForOAuth = false;
  bool _agreedToTerms = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;

  static const _googleWebClientId =
      '936997750810-d9k18t2710eesdh2bton3kduesri6b4s.apps.googleusercontent.com';
  static const _googleIosClientId =
      '765972336394-sbuakvc3n35ttq4milr37ddqeafhrjkh.apps.googleusercontent.com';
  static const _facebookAppId = '926390707142716';

  static const _privacyPolicyUrl =
      'https://krxton.github.io/Skill-Wallet-Kizuna/privacy-policy.html';
  static const _termsOfServiceUrl =
      'https://krxton.github.io/Skill-Wallet-Kizuna/terms-of-service.html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      unawaited(_initializeWebSocialSignIn());
    }
  }

  Future<void> _initializeWebSocialSignIn() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(clientId: _googleWebClientId);
      _googleAuthSubscription = googleSignIn.authenticationEvents.listen(
        _handleGoogleAuthenticationEvent,
        onError: _handleGoogleAuthenticationError,
      );

      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: _facebookAppId,
        cookie: true,
        xfbml: true,
        version: 'v23.0',
      );
    } catch (error) {
      debugPrint('Web social sign-in initialization error: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_googleAuthSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForOAuth) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading && _waitingForOAuth) {
          setState(() {
            _isLoading = false;
            _waitingForOAuth = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main layout (ปุ่มอยู่เดิมเสมอ) ──
            LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Logo
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Image.asset('assets/images/SWK_home.png',
                                height: 260),
                          ),
                        ),

                        // OAuth buttons
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _oauthButton(
                                    icon: Icons.email_outlined,
                                    text: l10n.email_loginWithEmail,
                                    color: Colors.grey.shade700,
                                    onTap: isLoading
                                        ? () {}
                                        : () => Navigator.pushNamed(
                                            context, AppRoutes.emailLogin),
                                  ),
                                  const SizedBox(height: 12),
                                  _oauthButton(
                                    icon: Icons.facebook,
                                    text: l10n.login_facebookBtn,
                                    color: Palette.facebook,
                                    onTap: isLoading
                                        ? () {}
                                        : () => _handleOAuth('facebook'),
                                  ),
                                  const SizedBox(height: 12),
                                  if (kIsWeb && _agreedToTerms)
                                    IgnorePointer(
                                      ignoring: isLoading,
                                      child: _googleWebButton(
                                        text: l10n.login_googleBtn,
                                      ),
                                    )
                                  else
                                    _googleButton(
                                      text: l10n.login_googleBtn,
                                      onTap: isLoading
                                          ? () {}
                                          : () => _handleOAuth('google'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Terms
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                          child: _buildTermsCheckbox(l10n),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // ── Loading overlay (ลอยอยู่บนทุกอย่าง) ──
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          l10n.auth_loading,
                          style: AppTextStyles.body(16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========== Terms Checkbox ==========
  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
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
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ========== OAuth Entry Point ==========
  void _handleOAuth(String provider) {
    if (!_agreedToTerms) {
      _showTermsDialog(provider);
      return;
    }
    if (provider == 'facebook') {
      _handleFacebookSignIn();
    } else {
      _handleGoogleSignIn();
    }
  }

  Future<void> _showTermsDialog(String provider) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          l10n.auth_tosDialogMsg,
          style: AppTextStyles.body(15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(_termsOfServiceUrl);
            },
            child: Text(
              l10n.auth_readTos,
              style: AppTextStyles.body(14, color: Palette.sky),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _agreedToTerms = true);
              if (provider == 'facebook') {
                _handleFacebookSignIn();
              } else {
                _handleGoogleSignIn();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Palette.sky),
            child: Text(
              l10n.auth_enter,
              style: AppTextStyles.body(14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== Facebook Sign-In ==========
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginTracking: LoginTracking.enabled,
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.tokenString;
        final facebookPhotoUrl = await _getFacebookProfilePhotoUrl();
        final user = await AuthService().signInWithSocial(
          provider: 'facebook',
          idToken: accessToken,
          accessToken: accessToken,
        );
        await StorageService().saveProvider('facebook');
        if (facebookPhotoUrl != null) {
          await StorageService().saveOAuthPhotoUrl(facebookPhotoUrl);
        } else if (user.image != null) {
          await StorageService().saveOAuthPhotoUrl(user.image!);
        }
        await _handlePostOAuth(
          provider: 'facebook',
          userId: user.id,
          email: user.email,
          fullName: user.name.isNotEmpty ? user.name : user.email.split('@')[0],
        );
      } else {
        setState(() => _isLoading = false);
        debugPrint('Facebook Sign-In cancelled: ${result.status}');
        if (mounted) {
          _showMessage(AppLocalizations.of(context)!
              .common_errorGeneric(result.status.toString()));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Facebook Sign-In error: $e');
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!
            .common_errorGeneric(e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<String?> _getFacebookProfilePhotoUrl() async {
    try {
      final facebookData = await FacebookAuth.instance.getUserData(
        fields: 'picture.width(500).height(500)',
      );
      final picture = facebookData['picture'];
      if (picture is! Map) return null;

      final data = picture['data'];
      if (data is! Map) return null;

      final url = data['url'];
      return url is String && url.isNotEmpty ? url : null;
    } catch (error) {
      // A profile image is optional; keep sign-in working and use the image
      // returned by Better Auth when the Graph API is unavailable.
      debugPrint('Facebook high-resolution photo error: $error');
      return null;
    }
  }

  // ========== Google Sign-In ==========
  Future<void> _handleGoogleSignIn() async {
    if (kIsWeb) {
      // Google Identity Services requires its SDK-rendered button on Web.
      return;
    }
    setState(() => _isLoading = true);

    try {
      await _nativeGoogleSignIn();
    } on GoogleSignInException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In cancelled by user');
        return;
      }
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        _showMessage(
            AppLocalizations.of(context)!.common_errorGeneric(e.toString()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        _showMessage(
            AppLocalizations.of(context)!.common_errorGeneric(e.toString()));
      }
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    try {
      final scopes = ['email', 'profile'];
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: _googleWebClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? _googleIosClientId
            : null,
      );

      final googleUser = await googleSignIn.authenticate();

      final String? fullName = googleUser.displayName;

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
              await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('No ID Token found from Google.');
      }

      await _completeGoogleSignIn(
        googleUser,
        accessToken: authorization.accessToken,
        fullName: fullName,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    if (!_agreedToTerms) {
      await GoogleSignIn.instance.signOut();
      if (mounted) _showTermsDialog('google');
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      await _completeGoogleSignIn(event.user);
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Google Web Sign-In error: $error');
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.common_errorGeneric(
            error.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  void _handleGoogleAuthenticationError(Object error) {
    debugPrint('Google Web authentication error: $error');
    if (mounted) {
      setState(() => _isLoading = false);
      _showMessage(
          AppLocalizations.of(context)!.common_errorGeneric(error.toString()));
    }
  }

  Future<void> _completeGoogleSignIn(
    GoogleSignInAccount googleUser, {
    String? accessToken,
    String? fullName,
  }) async {
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw Exception('No ID Token found from Google.');
    }

    final user = await AuthService().signInWithSocial(
      provider: 'google',
      idToken: idToken,
      accessToken: accessToken,
    );
    await StorageService().saveProvider('google');
    if (user.image != null) {
      await StorageService().saveOAuthPhotoUrl(user.image!);
    }
    await _handlePostOAuth(
      provider: 'google',
      userId: user.id,
      email: user.email,
      fullName: fullName ?? googleUser.displayName ?? user.name,
    );
  }

  // ========== Post-OAuth: Auto-detect Login vs Register ==========
  Future<void> _handlePostOAuth({
    required String provider,
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final hasAccount = await _checkParentExists();

    if (hasAccount) {
      // Existing user → sync email only (preserve user-edited name)
      await _syncUserData(email: email);
      // Load photo from user metadata (custom photo_url takes priority)
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        await userProvider.fetchParentData();
        if (provider == 'facebook' &&
            _isFacebookProfilePhotoUrl(userProvider.parentPhotoUrl)) {
          await userProvider.setPhotoFromOAuth(provider);
        }
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
      // New user → save to DB + freeze OAuth photo on first login
      await _saveUserToDatabase(
        userId: userId,
        email: email,
        fullName: fullName,
      );
      // Save OAuth photo once so it won't change when user's Google photo changes
      if (mounted) {
        await context.read<UserProvider>().setPhotoFromOAuth(provider);
      }

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

  bool _isFacebookProfilePhotoUrl(String? url) {
    if (url == null) return false;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('facebook.com') ||
        host.contains('fbcdn.net') ||
        host.contains('fbsbx.com');
  }

  // ========== Helpers ==========
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
      debugPrint('User synced via API: $parentName (id: $parentId)');

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
      debugPrint('User saved via API: $parentName');

      if (mounted) {
        context.read<UserProvider>().setParentName(parentName);
      }
    } catch (e) {
      debugPrint('Error saving user to database: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // ========== UI Components ==========
  Widget _oauthButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.heading(16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const _GoogleLogoIcon(size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.heading(16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleWebButton({required String text}) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the same app styling after accepting the terms. The web SDK
          // button remains on top to handle the Google sign-in interaction.
          _googleButton(text: text, onTap: () {}),
          Opacity(
            opacity: 0.01,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: buildGoogleSignInButton(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google "G" Logo ───────────────────────────────────────────────────────

class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.22;
    final arcR = size.width / 2 - sw / 2;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    double rad(double deg) => deg * math.pi / 180;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Blue: -10° → 90° (top-right going down)
    arc.color = blue;
    canvas.drawArc(rect, rad(-10), rad(100), false, arc);
    // Green: 90° → 170°
    arc.color = green;
    canvas.drawArc(rect, rad(90), rad(80), false, arc);
    // Yellow: 170° → 230°
    arc.color = yellow;
    canvas.drawArc(rect, rad(170), rad(60), false, arc);
    // Red: 230° → 350°
    arc.color = red;
    canvas.drawArc(rect, rad(230), rad(120), false, arc);

    // Blue crossbar (horizontal bar from center to right edge)
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - sw / 2, cx + arcR + sw / 2, cy + sw / 2),
      Paint()..color = blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
