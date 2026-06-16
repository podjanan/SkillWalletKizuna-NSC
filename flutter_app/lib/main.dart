import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/api_config.dart';
import 'services/deep_link_service.dart';
import 'services/storage_service.dart';
import 'services/mock_auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await StorageService().init();

  print('API_BASE_URL: ${ApiConfig.baseUrl}');

  MockAuthService.printDebugInfo();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SWKApp(),
    ),
  );
}

class SWKApp extends StatefulWidget {
  const SWKApp({super.key});

  @override
  State<SWKApp> createState() => _SWKAppState();

  static _SWKAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SWKAppState>();
}

class _SWKAppState extends State<SWKApp> {
  Locale _locale = const Locale('en');
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    await _loadUserData();

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      try {
        final initialUri = await _deepLinkService.getInitialLink();
        if (initialUri != null && mounted) {
          _handleDeepLink(initialUri);
        }
        _deepLinkService.startListening((uri) {
          if (mounted) _handleDeepLink(uri);
        });
      } catch (e) {
        print('⚠️ Deep links not supported on this platform: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchParentData();
      if (userProvider.currentParentName?.isNotEmpty == true) {
        print('👤 Parent name set: ${userProvider.currentParentName}');
      }
      await userProvider.fetchChildrenData();
    } catch (e) {
      print('⚠️ Fetch user data failed: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    print('📱 Deep link: $uri');
    // Deep links for OAuth are no longer needed — Better Auth uses direct API calls
  }

  @override
  void dispose() {
    _deepLinkService.stopListening();
    super.dispose();
  }

  void setLocale(Locale value) {
    setState(() => _locale = value);
  }

  @override
  Widget build(BuildContext context) {
    final appRoutes = Map<String, WidgetBuilder>.from(AppRoutes.routes);
    appRoutes.remove('/');

    return MaterialApp(
      title: 'SkillWalletKizuna',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: Container(
          decoration: BoxDecoration(gradient: Palette.appBackground),
          child: child!,
        ),
      ),
      home: const AuthWrapper(),
      routes: appRoutes,
    );
  }
}

// AuthWrapper — ตรวจสอบสถานะ login ด้วย Better Auth
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Developer mode bypass
    if (MockAuthService.isDeveloperMode) {
      try {
        await MockAuthService.createMockSession();
        if (mounted) {
          context.read<UserProvider>().setParentName('Developer (Mock User)');
        }
        setState(() {
          _isAuthenticated = true;
          _isInitialized = true;
        });
        return;
      } catch (e) {
        print('⚠️ Error initializing developer mode: $e');
      }
    }

    // Check Better Auth session (verifies token is valid with server)
    bool authenticated = false;
    final session = await AuthService().getSession();
    if (session != null) {
      authenticated = true;
      debugPrint('✅ Found valid Better Auth session');
    }

    if (authenticated && mounted) {
      final userProvider = context.read<UserProvider>();
      try {
        await userProvider.fetchChildrenData();
      } catch (_) {
        // network error — don't block user
      }
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (MockAuthService.isDeveloperMode) {
      return const HomeScreen();
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
