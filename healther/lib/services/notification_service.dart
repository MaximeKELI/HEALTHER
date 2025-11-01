import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String get baseUrl => ApiService().baseUrl.replaceAll('/api', '');
  IO.Socket? _socket;
  
  void connectSocket(int userId) {
    if (_socket != null && _socket!.connected) return;
    
    try {
      _socket = IO.io(
        baseUrl.replaceFirst('http://', 'ws://'),
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
      );

      _socket!.onConnect((_) {
        print('🔌 WebSocket connecté');
        _socket!.emit('join-user-room', userId);
      });

      _socket!.onDisconnect((_) {
        print('🔌 WebSocket déconnecté');
      });

      _socket!.onError((error) {
        print('❌ Erreur WebSocket: $error');
      });
    } catch (e) {
      print('Erreur connexion WebSocket: $e');
    }
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  void onNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('notification', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Obtenir les notifications de l'utilisateur
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'unread_only': unreadOnly.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/notifications')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode >= 400) {
      throw Exception('Erreur récupération notifications');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      headers: ApiService().headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur marquage notification');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: ApiService().headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur marquage notifications');
    }
  }

  // Compter les notifications non lues
  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/unread-count'),
      headers: ApiService().headers,
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur comptage notifications');
    }

    final data = json.decode(response.body);
    return data['count'] as int? ?? 0;
  }
}

