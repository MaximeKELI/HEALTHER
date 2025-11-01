import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Provider pour la gamification (badges, leaderboard, scores)
class GamificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Scores de l'utilisateur
  int _userScore = 0;
  int _userLevel = 1;
  List<String> _badges = [];
  int _diagnosticsCount = 0;
  int _totalContributions = 0;

  // Leaderboard
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = false;

  int get userScore => _userScore;
  int get userLevel => _userLevel;
  List<String> get badges => _badges;
  int get diagnosticsCount => _diagnosticsCount;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  String get userLevelName {
    if (_userLevel <= 5) return 'Débutant';
    if (_userLevel <= 10) return 'Intermédiaire';
    if (_userLevel <= 20) return 'Avancé';
    if (_userLevel <= 30) return 'Expert';
    return 'Maître';
  }

  // Calculer le niveau basé sur le score
  void _calculateLevel() {
    _userLevel = (_userScore / 100).floor() + 1;
    _updateBadges();
  }

  // Mettre à jour les badges
  void _updateBadges() {
    final newBadges = <String>[];

    if (_diagnosticsCount >= 1) newBadges.add('first_diagnostic');
    if (_diagnosticsCount >= 10) newBadges.add('diagnostic_milestone_10');
    if (_diagnosticsCount >= 50) newBadges.add('diagnostic_milestone_50');
    if (_diagnosticsCount >= 100) newBadges.add('diagnostic_milestone_100');

    if (_userLevel >= 5) newBadges.add('level_5');
    if (_userLevel >= 10) newBadges.add('level_10');
    if (_userLevel >= 20) newBadges.add('level_20');

    if (_totalContributions >= 1) newBadges.add('contributor');
    if (_totalContributions >= 10) newBadges.add('active_contributor');

    _badges = newBadges;
  }

  // Ajouter des points pour un diagnostic créé
  void addDiagnosticPoints({int points = 10}) {
    _userScore += points;
    _diagnosticsCount++;
    _totalContributions++;
    _calculateLevel();
    notifyListeners();
    _saveToLocal();
  }

  // Ajouter des points pour feedback ML
  void addFeedbackPoints({int points = 5}) {
    _userScore += points;
    _totalContributions++;
    _calculateLevel();
    notifyListeners();
    _saveToLocal();
  }

  // Charger les scores depuis le backend (si disponible)
  Future<void> loadUserScores() async {
    try {
      // TODO: Créer endpoint backend pour scores utilisateur
      // Pour l'instant, on utilise le stockage local
      await _loadFromLocal();
    } catch (e) {
      print('Erreur chargement scores: $e');
    }
  }

  // Charger le leaderboard
  Future<void> loadLeaderboard({String? region}) async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      // TODO: Créer endpoint backend pour leaderboard
      // Pour l'instant, mock data
      _leaderboard = [
        {'username': 'Agent1', 'score': 450, 'diagnostics': 45, 'region': 'Lomé'},
        {'username': 'Agent2', 'score': 380, 'diagnostics': 38, 'region': 'Kara'},
        {'username': 'Agent3', 'score': 320, 'diagnostics': 32, 'region': 'Lomé'},
      ];
    } catch (e) {
      print('Erreur chargement leaderboard: $e');
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // Sauvegarder localement
  Future<void> _saveToLocal() async {
    // TODO: Utiliser shared_preferences
  }

  // Charger depuis local
  Future<void> _loadFromLocal() async {
    // TODO: Utiliser shared_preferences
  }

  // Obtenir l'icône d'un badge
  static String getBadgeIcon(String badgeId) {
    switch (badgeId) {
      case 'first_diagnostic':
        return '🥉';
      case 'diagnostic_milestone_10':
        return '🥈';
      case 'diagnostic_milestone_50':
        return '🥇';
      case 'diagnostic_milestone_100':
        return '👑';
      case 'level_5':
        return '⭐';
      case 'level_10':
        return '⭐⭐';
      case 'level_20':
        return '⭐⭐⭐';
      case 'contributor':
        return '🤝';
      case 'active_contributor':
        return '🔥';
      default:
        return '🏆';
    }
  }

  static String getBadgeName(String badgeId) {
    switch (badgeId) {
      case 'first_diagnostic':
        return 'Premier Diagnostic';
      case 'diagnostic_milestone_10':
        return '10 Diagnostics';
      case 'diagnostic_milestone_50':
        return '50 Diagnostics';
      case 'diagnostic_milestone_100':
        return '100 Diagnostics';
      case 'level_5':
        return 'Niveau 5';
      case 'level_10':
        return 'Niveau 10';
      case 'level_20':
        return 'Niveau 20';
      case 'contributor':
        return 'Contributeur';
      case 'active_contributor':
        return 'Contributeur Actif';
      default:
        return 'Badge';
    }
  }
}

