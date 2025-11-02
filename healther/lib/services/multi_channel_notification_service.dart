import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

/// Service pour Notifications Multicanaux
class MultiChannelNotificationService {
  final ApiService _apiService = ApiService();
  
  String get baseUrl {
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

  /// Envoyer une notification SMS
  Future<Map<String, dynamic>> sendSMS(String to, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications-multichannel/sms'),
        headers: _headers,
        body: json.encode({
          'to': to,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur envoi SMS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur envoi SMS: $e');
    }
  }

  /// Envoyer une notification WhatsApp
  Future<Map<String, dynamic>> sendWhatsApp(
    String to,
    String message, {
    String? provider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications-multichannel/whatsapp'),
        headers: _headers,
        body: json.encode({
          'to': to,
          'message': message,
          if (provider != null) 'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur envoi WhatsApp: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur envoi WhatsApp: $e');
    }
  }

  /// Envoyer un Email
  Future<Map<String, dynamic>> sendEmail({
    required String to,
    required String subject,
    required String text,
    String? html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications-multichannel/email'),
        headers: _headers,
        body: json.encode({
          'to': to,
          'subject': subject,
          'text': text,
          if (html != null) 'html': html,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur envoi Email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur envoi Email: $e');
    }
  }

  /// Envoyer une notification Push
  Future<Map<String, dynamic>> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications-multichannel/push'),
        headers: _headers,
        body: json.encode({
          'tokens': tokens,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur envoi Push: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur envoi Push: $e');
    }
  }

  /// Envoyer sur plusieurs canaux
  Future<Map<String, dynamic>> sendMultiChannel({
    required String message,
    required List<String> channels,
    String? phone,
    String? email,
    List<String>? fcmTokens,
    String? subject,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications-multichannel/multichannel'),
        headers: _headers,
        body: json.encode({
          'message': message,
          'channels': channels,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (fcmTokens != null) 'fcmTokens': fcmTokens,
          if (subject != null) 'subject': subject,
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur envoi multicanaux: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur envoi multicanaux: $e');
    }
  }
}

