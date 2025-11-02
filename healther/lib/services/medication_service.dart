import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

/// Service pour Suivi Médication Avancé
class MedicationService {
  final ApiService _apiService = ApiService();
  
  String get baseUrl {
    // Utiliser la même méthode que ApiService pour obtenir l'URL
    const String envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:3000/api';
  }
  
  Map<String, String> get _headers {
    final token = _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Rechercher un médicament dans OpenFDA
  Future<Map<String, dynamic>> searchDrug(String drugName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications/search?drugName=${Uri.encodeComponent(drugName)}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur recherche médicament: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur recherche médicament: $e');
    }
  }

  /// Vérifier les interactions médicamenteuses
  Future<Map<String, dynamic>> checkInteractions(List<String> drugNames) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/check-interactions'),
        headers: _headers,
        body: json.encode({'drugNames': drugNames}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur vérification interactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur vérification interactions: $e');
    }
  }

  /// Créer un rappel de médicament
  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/reminders'),
        headers: _headers,
        body: json.encode(reminderData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur création rappel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur création rappel: $e');
    }
  }

  /// Récupérer les rappels de l'utilisateur
  Future<Map<String, dynamic>> getReminders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications/reminders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur récupération rappels: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération rappels: $e');
    }
  }

  /// Marquer une prise de médicament
  Future<Map<String, dynamic>> markTaken(int reminderId, {String? takenAt}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/reminders/$reminderId/taken'),
        headers: _headers,
        body: json.encode({'takenAt': takenAt ?? DateTime.now().toIso8601String()}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur marquage médicament: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur marquage médicament: $e');
    }
  }

  /// Obtenir les statistiques d'observance
  Future<Map<String, dynamic>> getAdherenceStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }

      String url = '$baseUrl/medications/adherence';
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur statistiques observance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur statistiques observance: $e');
    }
  }
}

