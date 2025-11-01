import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  String get baseUrl => ApiService().baseUrl;

  /// Recherche avancée de diagnostics
  Future<Map<String, dynamic>> searchDiagnostics({
    int? userId,
    String? maladieType,
    String? region,
    String? statut,
    String? dateDebut,
    String? dateFin,
    double? confianceMin,
    double? confianceMax,
    double? qualityMin,
    String? sortBy,
    String? sortOrder,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search/diagnostics'),
      headers: ApiService().headers,
      body: json.encode({
        'user_id': userId,
        'maladie_type': maladieType,
        'region': region,
        'statut': statut,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        'confiance_min': confianceMin,
        'confiance_max': confianceMax,
        'quality_min': qualityMin,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'limit': limit,
        'offset': offset,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur recherche diagnostics');
    }

    return json.decode(response.body);
  }

  /// Recherche de patients
  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final uri = Uri.parse('$baseUrl/search/patients').replace(queryParameters: {'q': query});
    
    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur recherche patients');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  /// Sauvegarder un filtre de recherche
  Future<void> saveSearchFilter(String name, Map<String, dynamic> filters) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search/filters'),
      headers: ApiService().headers,
      body: json.encode({
        'name': name,
        'filters': filters,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur sauvegarde filtre');
    }
  }

  /// Obtenir les filtres sauvegardés
  Future<List<Map<String, dynamic>>> getSavedFilters() async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/filters'),
      headers: ApiService().headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération filtres');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }
}
