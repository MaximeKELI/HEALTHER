import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class TOTPService {
  static final TOTPService _instance = TOTPService._internal();
  factory TOTPService() => _instance;
  TOTPService._internal();

  String get baseUrl => ApiService().baseUrl;

  /// Générer un secret TOTP et QR code
  Future<Map<String, dynamic>> generateTOTPSecret() async {
    final response = await http.post(
      Uri.parse('$baseUrl/totp/generate'),
      headers: ApiService().headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur génération secret TOTP');
    }

    return json.decode(response.body);
  }

  /// Activer 2FA
  Future<bool> enable2FA(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/totp/enable'),
      headers: ApiService().headers,
      body: json.encode({'token': token}),
    );

    return response.statusCode == 200;
  }

  /// Désactiver 2FA
  Future<bool> disable2FA() async {
    final response = await http.post(
      Uri.parse('$baseUrl/totp/disable'),
      headers: ApiService().headers,
    );

    return response.statusCode == 200;
  }
}
