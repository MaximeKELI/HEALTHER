import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'providers/diagnostic_provider.dart';
import 'services/localization_service.dart';
import 'services/accessibility_service.dart';
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
    final accessibilityService = AccessibilityService();
    
    // Initialiser les services en arrière-plan
    _initializeServices();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosticProvider()),
      ],
      child: MaterialApp(
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
        theme: accessibilityService.getTheme(ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.green,
          ),
          useMaterial3: true,
        )),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
