import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  String get baseUrl => ApiService().baseUrl;

  /// Envoyer un message dans le chat d'un diagnostic
  Future<int> sendMessage({
    required int diagnosticId,
    required String message,
    List<int>? mentions,
    List<int>? attachments,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/messages'),
      headers: ApiService().headers,
      body: json.encode({
        'diagnostic_id': diagnosticId,
        'message': message,
        'mentions': mentions ?? [],
        'attachments': attachments ?? [],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur envoi message');
    }

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  /// Obtenir les messages d'un diagnostic
  Future<List<Map<String, dynamic>>> getMessages(
    int diagnosticId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/diagnostic/$diagnosticId')
        .replace(queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération messages');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }
}
