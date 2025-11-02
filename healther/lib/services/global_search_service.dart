import '../services/api_service.dart';

/// Service de recherche globale
class GlobalSearchService {
  static final GlobalSearchService _instance = GlobalSearchService._internal();
  factory GlobalSearchService() => _instance;
  GlobalSearchService._internal();

  final ApiService _apiService = ApiService();
  final List<String> _searchHistory = [];

  /// Recherche globale dans diagnostics, patients, etc.
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    String? type, // 'diagnostics', 'patients', 'all'
  }) async {
    if (query.trim().isEmpty) {
      return {
        'diagnostics': [],
        'patients': [],
        'total': 0,
      };
    }

    try {
      // Recherche diagnostics - récupérer tous et filtrer côté client
      // Note: Pour une vraie recherche, il faudrait ajouter un paramètre 'search' au backend
      final allDiagnostics = await _apiService.getDiagnostics(limit: 100);
      
      // Filtrer les diagnostics qui correspondent à la requête
      final diagnostics = allDiagnostics.where((diagnostic) {
        final queryLower = query.toLowerCase();
        return diagnostic.maladieTypeLabel.toLowerCase().contains(queryLower) ||
               diagnostic.statutLabel.toLowerCase().contains(queryLower) ||
               (diagnostic.region != null && diagnostic.region!.toLowerCase().contains(queryLower));
      }).take(20).toList();

      // Recherche patients (via diagnostics) - extraire régions uniques comme exemple
      final patients = <String>{};
      for (var diagnostic in diagnostics) {
        if (diagnostic.region != null && diagnostic.region!.toLowerCase().contains(query.toLowerCase())) {
          patients.add(diagnostic.region!);
        }
      }

      // Sauvegarder dans l'historique
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      }

      return {
        'diagnostics': diagnostics,
        'patients': patients.toList(),
        'total': diagnostics.length + patients.length,
        'query': query,
      };
    } catch (e) {
      return {
        'diagnostics': [],
        'patients': [],
        'total': 0,
        'error': e.toString(),
      };
    }
  }

  /// Obtenir l'historique de recherche
  List<String> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  /// Effacer l'historique
  void clearHistory() {
    _searchHistory.clear();
  }

  /// Suggestions basées sur la requête
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      return getSearchHistory().take(5).toList();
    }

    // Suggestions depuis l'historique
    final historySuggestions = _searchHistory
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();

    // Suggestions basées sur les données (à implémenter)
    // Par exemple, régions fréquentes, maladies, etc.

    return historySuggestions;
  }
}

