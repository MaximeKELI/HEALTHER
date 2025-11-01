import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;


class ChatbotMessage {
  final int? id;
  final String role; // 'user' or 'assistant'
  final String message;
  final DateTime? createdAt;

  ChatbotMessage({
    this.id,
    required this.role,
    required this.message,
    this.createdAt,
  });

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id'] as int?,
      role: json['role']?.toString() ?? 'user',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ChatbotConversation {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime? closedAt;

  ChatbotConversation({
    required this.id,
    required this.title,
    this.createdAt,
    this.closedAt,
  });

  factory ChatbotConversation.fromJson(Map<String, dynamic> json) {
    return ChatbotConversation(
      id: json['id'] as int,
      title: json['title']?.toString() ?? 'Nouvelle conversation',
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      closedAt: json['closed_at'] != null && json['closed_at'] is String
          ? DateTime.tryParse(json['closed_at'] as String)
          : null,
    );
  }
}

class ChatbotService {
  final ApiService _apiService = ApiService();

  String get _baseUrl => ApiService.baseUrl;

  // Récupérer ou créer une conversation
  Future<Map<String, dynamic>> getOrCreateConversation() async {
    // Utiliser directement http avec gestion d'erreur manuelle
    final response = await http.get(
      Uri.parse('$_baseUrl/chatbot/conversation'),
      headers: _apiService.headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
    final data = json.decode(response.body);

    return {
      'conversation': ChatbotConversation.fromJson(data['conversation']),
      'messages': (data['messages'] as List?)
              ?.map((msg) => ChatbotMessage.fromJson(msg))
              .toList() ??
          [],
    };
  }

  // Envoyer un message au chatbot
  Future<Map<String, ChatbotMessage>> sendMessage(
    String message, {
    int? conversationId,
    Map<String, dynamic>? context,
  }) async {
    final body = {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
      if (context != null) 'context': context,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/chatbot/message'),
      headers: {
        ..._apiService.headers,
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
    final data = json.decode(response.body);

    return {
      'user_message': ChatbotMessage.fromJson(data['user_message']),
      'ai_message': ChatbotMessage.fromJson(data['ai_message']),
    };
  }

  // Récupérer toutes les conversations
  Future<List<ChatbotConversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chatbot/conversations'),
      headers: _apiService.headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
    final data = json.decode(response.body) as List;

    return data.map((conv) => ChatbotConversation.fromJson(conv)).toList();
  }

  // Fermer une conversation
  Future<void> closeConversation(int conversationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chatbot/conversation/$conversationId/close'),
      headers: _apiService.headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}

