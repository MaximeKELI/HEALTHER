import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  String get baseUrl => ApiService.baseUrl.replaceAll('/api', '');

  // Obtenir toutes les zones géofencing actives
  Future<List<Map<String, dynamic>>> getActiveGeofences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/geofencing'),
      headers: ApiService().headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur récupération géofences');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // Vérifier les alertes géofencing
  Future<Map<String, dynamic>> checkAlerts({
    String? region,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/api/geofencing/check-alerts')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode >= 400) {
      throw Exception('Erreur vérification alertes');
    }

    return json.decode(response.body);
  }

  // Obtenir heatmap des cas
  Future<List<Map<String, dynamic>>> getHeatmap({
    String? region,
    String? maladieType,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (maladieType != null) queryParams['maladie_type'] = maladieType;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/api/geofencing/heatmap')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode >= 400) {
      throw Exception('Erreur récupération heatmap');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }
}

