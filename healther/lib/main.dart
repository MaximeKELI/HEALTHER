import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'services/onboarding_service.dart';
import 'screens/global_search_screen.dart';
import 'providers/diagnostic_provider.dart';
import 'services/localization_service.dart';
import 'providers/ml_feedback_provider.dart';
import 'services/accessibility_service.dart';
import 'providers/notification_provider.dart';
import 'providers/gamification_provider.dart';
import 'services/realtime_stats_service.dart';
import 'services/keyboard_shortcuts_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> _initializeServices() async {
  try {
    final localizationService = LocalizationService();
    final accessibilityService = AccessibilityService();
    
    // Charger les préférences de manière asynchrone mais non bloquante
    localizationService.loadSavedLocale().catchError((e) {
      print('Erreur chargement locale: $e');
    });
    accessibilityService.loadPreferences().catchError((e) {
      print('Erreur chargement accessibilité: $e');
    });
    
    // Attendre un court délai pour permettre l'initialisation
    await Future.delayed(const Duration(milliseconds: 100));
  } catch (e) {
    // En cas d'erreur, continuer avec les valeurs par défaut
    print('Erreur initialisation services: $e');
  }
}

void main() {
  // Gestionnaire d'erreur global
  FlutterError.onError = (FlutterErrorDetails details) {
    // Afficher dans la console
    FlutterError.presentError(details);
    
    // Logger les informations critiques
    print('═══════════════════════════════════════════');
    print('❌ ERREUR FLUTTER');
    print('═══════════════════════════════════════════');
    print('Type: ${details.exception.runtimeType}');
    print('Message: ${details.exception}');
    print('Ligne: ${details.stack?.toString().split('\n').first ?? "N/A"}');
    print('═══════════════════════════════════════════');
    
    // En mode debug, afficher le stack complet
    if (kDebugMode) {
      print('Stack complet:');
      print(details.stack);
    }
  };
  
  // Gestion des erreurs asynchrones
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    print('═══════════════════════════════════════════');
    print('❌ ERREUR ASYNCHRONE NON GÉRÉE');
    print('═══════════════════════════════════════════');
    print('Erreur: $error');
    print('Stack: $stack');
    print('═══════════════════════════════════════════');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services (singletons)
    final localizationService = LocalizationService();
    
    // Initialiser les services en arrière-plan
    _initializeServices();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosticProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MLFeedbackProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeStatsService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'HEALTHER',
            debugShowCheckedModeBanner: false,
            locale: localizationService.currentLocale,
            supportedLocales: LocalizationService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: themeProvider.getTheme(ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                primary: themeProvider.primaryColor,
                secondary: themeProvider.secondaryColor,
              ),
              useMaterial3: true,
            )),
            darkTheme: themeProvider.getTheme(ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                primary: themeProvider.primaryColor,
                secondary: themeProvider.secondaryColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            )),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/search': (context) => const GlobalSearchScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _checkingOnboarding = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      final completed = await _onboardingService.isOnboardingCompleted();
      if (mounted) {
        setState(() {
          _checkingOnboarding = false;
          _needsOnboarding = !completed;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _checkingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_checkingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.isAuthenticated) {
      if (_needsOnboarding) {
        return const OnboardingScreen();
      }
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
