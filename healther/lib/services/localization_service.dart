import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _localeKey = 'app_locale';
  Locale _currentLocale = const Locale('fr'); // Utiliser fr au lieu de fr_TG pour compatibilité

  Locale get currentLocale => _currentLocale;

  /// Charger la locale sauvegardée
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString(_localeKey);
    
    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length >= 1) {
        _currentLocale = Locale(parts[0]); // Utiliser seulement le code de langue pour compatibilité
      }
    }
  }

  /// Changer la locale
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    // Sauvegarder seulement le code de langue pour compatibilité
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Obtenir les locales supportées
  static List<Locale> get supportedLocales => [
    const Locale('fr'), // Français
    const Locale('en'), // Anglais
  ];
}

/// Classe pour les traductions
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Traductions communes
  String get appTitle => locale.languageCode == 'fr' ? 'M.A.D.E' : 'M.A.D.E';
  String get login => locale.languageCode == 'fr' ? 'Connexion' : 'Login';
  String get password => locale.languageCode == 'fr' ? 'Mot de passe' : 'Password';
  String get username => locale.languageCode == 'fr' ? 'Nom d\'utilisateur' : 'Username';
  String get diagnostics => locale.languageCode == 'fr' ? 'Diagnostics' : 'Diagnostics';
  String get dashboard => locale.languageCode == 'fr' ? 'Tableau de bord' : 'Dashboard';
  String get logout => locale.languageCode == 'fr' ? 'Déconnexion' : 'Logout';
  
  // Messages d'erreur
  String get errorConnection => locale.languageCode == 'fr' 
      ? 'Erreur de connexion. Vérifiez vos identifiants.'
      : 'Connection error. Check your credentials.';
  
  String get errorNetwork => locale.languageCode == 'fr'
      ? 'Erreur réseau. Vérifiez votre connexion.'
      : 'Network error. Check your connection.';
  
  // Messages de succès
  String get successDiagnostic => locale.languageCode == 'fr'
      ? 'Diagnostic créé avec succès'
      : 'Diagnostic created successfully';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
