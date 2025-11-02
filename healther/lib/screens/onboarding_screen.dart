import 'home_screen.dart';
import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../services/haptic_feedback_service.dart';

/// Écran d'onboarding interactif
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final HapticFeedbackService _haptic = HapticFeedbackService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.medical_services,
      title: 'Bienvenue sur HEALTHER',
      description: 'Plateforme intelligente de diagnostic médical assisté par IA pour améliorer la santé publique.',
      color: Colors.blue,
    ),
    OnboardingPage(
      icon: Icons.camera_alt,
      title: 'Diagnostic Rapide',
      description: 'Capturez une image et obtenez une analyse instantanée avec notre IA avancée.',
      color: Colors.green,
    ),
    OnboardingPage(
      icon: Icons.analytics,
      title: 'Tableau de Bord',
      description: 'Visualisez vos statistiques et suivez les tendances en temps réel.',
      color: Colors.orange,
    ),
    OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Assistant IA',
      description: 'Obtenez de l\'aide instantanée avec notre chatbot et assistant vocal.',
      color: Colors.purple,
    ),
    OnboardingPage(
      icon: Icons.offline_bolt,
      title: 'Mode Offline',
      description: 'Travaillez sans connexion. Vos données seront synchronisées automatiquement.',
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _haptic.selectionClick();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _haptic.selectionClick();
    }
  }

  void _skip() {
    _haptic.mediumImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await _onboardingService.completeOnboarding();
    _haptic.success();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton Skip
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Précédent'),
                    )
                  else
                    const SizedBox(),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildOnboardingPage(page);
                },
              ),
            ),
            
            // Indicateurs et bouton
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicateurs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 120,
            color: page.color,
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: page.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

