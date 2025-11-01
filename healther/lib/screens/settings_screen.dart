import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/accessibility_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalizationService _localizationService = LocalizationService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  Locale? _currentLocale;
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _hapticEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _localizationService.loadSavedLocale();
    await _accessibilityService.loadPreferences();
    
    setState(() {
      _currentLocale = _localizationService.currentLocale;
      _fontSize = _accessibilityService.fontSize;
      _highContrast = _accessibilityService.highContrast;
      _hapticEnabled = _accessibilityService.hapticEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Langue
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              subtitle: Text(_currentLocale?.languageCode == 'fr' ? 'Français' : 'English'),
              children: [
                ListTile(
                  title: const Text('Français'),
                  trailing: _currentLocale?.languageCode == 'fr'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    await _localizationService.setLocale(const Locale('fr'));
                    setState(() => _currentLocale = const Locale('fr'));
                  },
                ),
                ListTile(
                  title: const Text('English'),
                  trailing: _currentLocale?.languageCode == 'en'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    await _localizationService.setLocale(const Locale('en'));
                    setState(() => _currentLocale = const Locale('en'));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Accessibilité
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.accessibility),
                      SizedBox(width: 16),
                      Text(
                        'Accessibilité',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Taille de police
                ListTile(
                  title: const Text('Taille de police'),
                  subtitle: Slider(
                    value: _fontSize,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(_fontSize * 100).toInt()}%',
                    onChanged: (value) async {
                      await _accessibilityService.setFontSize(value);
                      setState(() => _fontSize = value);
                    },
                  ),
                ),
                // Contraste élevé
                SwitchListTile(
                  title: const Text('Contraste élevé'),
                  subtitle: const Text('Améliore la lisibilité'),
                  value: _highContrast,
                  onChanged: (value) async {
                    await _accessibilityService.setHighContrast(value);
                    setState(() => _highContrast = value);
                  },
                ),
                // Retour haptique
                SwitchListTile(
                  title: const Text('Retour haptique'),
                  subtitle: const Text('Vibrations lors des interactions'),
                  value: _hapticEnabled,
                  onChanged: (value) async {
                    await _accessibilityService.setHapticEnabled(value);
                    setState(() => _hapticEnabled = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // À propos
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('À propos'),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('HEALTHER'),
                    content: const Text(
                      'Plateforme de diagnostic médical\nVersion 1.0.0\n\n© 2025 HEALTHER',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

