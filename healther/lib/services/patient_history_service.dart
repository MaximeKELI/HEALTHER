import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class PatientHistoryService {
  static final PatientHistoryService _instance = PatientHistoryService._internal();
  factory PatientHistoryService() => _instance;
  PatientHistoryService._internal();

  String get baseUrl => ApiService.baseUrl;

  /// Obtenir l'historique d'un patient
  Future<List<Map<String, dynamic>>> getPatientHistory(String identifier) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient-history/$identifier'),
      headers: ApiService().headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération historique');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  /// Obtenir le profil patient consolidé
  Future<Map<String, dynamic>> getPatientProfile(String identifier) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient-history/$identifier/profile'),
      headers: ApiService().headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération profil patient');
    }

    return json.decode(response.body);
  }

  /// Ajouter un événement à l'historique
  Future<void> addPatientEvent({
    required String patientIdentifier,
    int? diagnosticId,
    required String eventType,
    Map<String, dynamic>? details,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient-history'),
      headers: ApiService().headers,
      body: json.encode({
        'patient_identifier': patientIdentifier,
        'diagnostic_id': diagnosticId,
        'event_type': eventType,
        'details': details ?? {},
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur ajout événement historique');
    }
  }
}
