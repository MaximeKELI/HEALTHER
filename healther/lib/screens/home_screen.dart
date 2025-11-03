import 'quiz_screen.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'diagnostic_screen.dart';
import 'prediction_screen.dart';
import 'map_heatmap_screen.dart';
import 'lab_results_screen.dart';
import 'gamification_screen.dart';
import 'notifications_screen.dart';
import 'global_search_screen.dart';
import 'barcode_scanner_screen.dart';
import 'voice_assistant_screen.dart';
import 'contact_tracing_screen.dart';
import 'ocr_prescription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_patient_screen.dart';
import 'realtime_dashboard_screen.dart';
import 'video_consultation_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_helper.dart';
import 'medication_reminders_screen.dart';
import '../widgets/quick_actions_fab.dart';
import '../services/haptic_feedback_service.dart';
import '../services/keyboard_shortcuts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final KeyboardShortcutsService _shortcutsService = KeyboardShortcutsService();
  final HapticFeedbackService _haptic = HapticFeedbackService();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Widget> _screens = [
    const DiagnosticScreen(),
    const HistoryScreen(),
    const DashboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
    _setupGlobalSearch();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    _shortcutsService.registerShortcut(
      keys: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK),
      callback: () => _openGlobalSearch(),
      description: 'Ouvrir la recherche globale',
    );
    _shortcutsService.registerShortcut(
      keys: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
      callback: () => _newDiagnostic(),
      description: 'Nouveau diagnostic',
    );
    _shortcutsService.registerShortcut(
      keys: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.slash),
      callback: () => _showHelp(),
      description: 'Aide',
    );
    _shortcutsService.registerShortcut(
      keys: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma),
      callback: () => _openSettings(),
      description: 'Paramètres',
    );
  }

  void _setupGlobalSearch() {
    // Setup global search avec Ctrl+K
  }

  void _openGlobalSearch() {
    _haptic.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
    );
  }

  void _newDiagnostic() {
    _haptic.selectionClick();
    setState(() => _currentIndex = 0);
  }

  void _showHelp() {
    _haptic.selectionClick();
    _showShortcutsHelp();
  }

  void _openSettings() {
    _haptic.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showShortcutsHelp() {
    final shortcuts = _shortcutsService.getHelpShortcuts();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raccourcis Clavier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: shortcuts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return KeyboardShortcutsService().buildShortcuts(
      context: context,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('HEALTHER'),
              if (user != null)
                Text(
                  user.fullName.isNotEmpty && user.fullName != user.username
                      ? user.fullName
                      : user.username,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                ),
            ],
          ),
          actions: [
            // Recherche globale
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _openGlobalSearch,
              tooltip: 'Recherche (Ctrl+K)',
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                _haptic.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
              tooltip: 'Notifications',
            ),
            // Aide
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelp,
              tooltip: 'Aide (Ctrl+/)',
            ),
            if (isDesktop)
              PopupMenuButton<String>(
                tooltip: 'Plus de pages',
                onSelected: (value) {
                  switch (value) {
                    case 'realtime':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeDashboardScreen()));
                      break;
                    case 'chatbot':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
                      break;
                    case 'gamification':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()));
                      break;
                    case 'voice':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()));
                      break;
                    case 'heatmap':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapHeatmapScreen()));
                      break;
                    case 'barcode':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BarcodeScannerScreen(onBarcodeScanned: (b, f) {})));
                      break;
                    case 'analytics':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                      break;
                    case 'ocr':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRPrescriptionScreen()));
                      break;
                    case 'prediction':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictionScreen()));
                      break;
                    case 'alerts':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                      break;
                    case 'gallery':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()));
                      break;
                    case 'quiz':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
                      break;
                    case 'profile':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      break;
                    case 'settings':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      break;
                    case 'video':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoConsultationScreen(consultationId: 1, doctorId: 1, patientId: 1)));
                      break;
                    case 'lab':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LabResultsScreen()));
                      break;
                    case 'meds':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationRemindersScreen()));
                      break;
                    case 'contact':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactTracingScreen()));
                      break;
                    case 'patientDashboard':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPatientScreen()));
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'realtime', child: Text('Dashboard Temps Réel')),
                  const PopupMenuItem(value: 'chatbot', child: Text('Chatbot IA')),
                  const PopupMenuItem(value: 'gamification', child: Text('Gamification')),
                  const PopupMenuItem(value: 'voice', child: Text('Assistant Vocal IA')),
                  const PopupMenuItem(value: 'heatmap', child: Text('Carte Heatmap')),
                  const PopupMenuItem(value: 'barcode', child: Text('Scanner Code-barres')),
                  const PopupMenuItem(value: 'analytics', child: Text('Analytics & Rapports')),
                  const PopupMenuItem(value: 'ocr', child: Text('Scan Prescription')),
                  const PopupMenuItem(value: 'prediction', child: Text('Prédiction Épidémique')),
                  const PopupMenuItem(value: 'alerts', child: Text('Alertes Proactives')),
                  const PopupMenuItem(value: 'gallery', child: Text('Galerie de Photos')),
                  const PopupMenuItem(value: 'quiz', child: Text('Quiz Éducatif')),
                  const PopupMenuItem(value: 'video', child: Text('Vidéoconsultation')),
                  const PopupMenuItem(value: 'lab', child: Text('Résultats Labo')),
                  const PopupMenuItem(value: 'meds', child: Text('Rappels Médication')),
                  const PopupMenuItem(value: 'contact', child: Text('Contact Tracing')),
                  const PopupMenuItem(value: 'patientDashboard', child: Text('Dashboard Patient')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'profile', child: Text('Profil')),
                  const PopupMenuItem(value: 'settings', child: Text('Paramètres')),
                ],
              ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              // Naviguer vers la route racine pour que AuthWrapper gère la redirection
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false, // Retire toutes les routes précédentes
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Navigation latérale pour desktop
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.camera_alt),
                      label: Text('Diagnostic'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history),
                      label: Text('Historique'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Contenu principal
                Expanded(child: _screens[_currentIndex]),
              ],
            )
          : _screens[_currentIndex],
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt),
                  label: 'Diagnostic',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Historique',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
              ],
            )
          : null,
      floatingActionButton: !isDesktop
          ? QuickActionsFAB(
              onNewDiagnostic: () {
                setState(() => _currentIndex = 0);
              },
              onScanPrescription: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OCRPrescriptionScreen()),
                );
              },
              onScanBarcode: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarcodeScannerScreen(
                      onBarcodeScanned: (barcode, format) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code-barres scanné: $barcode')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              onVoiceCommand: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
                );
              },
            )
          : null,
      drawer: isDesktop ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: user?.profilePictureUrl != null
                        ? NetworkImage(user!.profilePictureUrl!)
                        : null,
                    child: user?.profilePictureUrl == null
                        ? Text(
                            user?.username[0].toUpperCase() ?? 'U',
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user != null
                        ? (user.fullName.isNotEmpty && user.fullName != user.username
                            ? user.fullName
                            : user.username)
                        : 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user != null)
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  if (user?.centreSante != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        user!.centreSante!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize),
              title: const Text('Dashboard Temps Réel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RealtimeDashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text('Chatbot IA'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Gamification'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamificationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Assistant Vocal IA'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Carte Heatmap'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapHeatmapScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scanner Code-barres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarcodeScannerScreen(
                      onBarcodeScanned: (barcode, format) {
                        // TODO: Traiter le code-barres scanné
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code-barres scanné: $barcode')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics & Rapports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Scan Prescription'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OCRPrescriptionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Prédiction Épidémique'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PredictionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Alertes Proactives'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie de Photos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GalleryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Quiz Éducatif'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

