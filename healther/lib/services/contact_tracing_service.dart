import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour Contact Tracing / Investigation d'Épidémie
class ContactTracingService {
  final ApiService _apiService = ApiService();
  String get baseUrl => _apiService._baseUrl;
  
  Map<String, String> get _headers {
    final token = _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Trouver les contacts d'un diagnostic
  Future<Map<String, dynamic>> findContacts(int diagnosticId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contact-tracing/diagnostic/$diagnosticId/contacts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur récupération contacts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur contact tracing: $e');
    }
  }

  /// Construire le graphique de transmission
  Future<Map<String, dynamic>> getTransmissionGraph(
    int patientId, {
    int maxDepth = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contact-tracing/patient/$patientId/transmission-graph?maxDepth=$maxDepth'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur récupération graphe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur transmission graph: $e');
    }
  }

  /// Calculer le R0 (taux de reproduction)
  Future<Map<String, dynamic>> calculateR0({
    String? region,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '/contact-tracing/r0';
      final queryParams = <String>[];

      if (region != null) {
        queryParams.add('region=${Uri.encodeComponent(region)}');
      }

      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }

      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }

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
        throw Exception('Erreur calcul R0: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur calcul R0: $e');
    }
  }

  /// Générer rapport d'investigation
  Future<Map<String, dynamic>> generateInvestigationReport(
    int diagnosticId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contact-tracing/diagnostic/$diagnosticId/investigation-report'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur génération rapport: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur rapport investigation: $e');
    }
  }
}

