import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur chargement notifications: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Erreur comptage notifications: $e');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications();
      await _loadUnreadCount();
    } catch (e) {
      print('Erreur marquage notification: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      await _loadUnreadCount();
    } catch (e) {
      print('Erreur marquage notifications: $e');
    }
  }

  void connectSocket(int userId) {
    _notificationService.connectSocket(userId);
    _notificationService.onNotification((notification) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    });
  }

  void disconnectSocket() {
    _notificationService.disconnectSocket();
  }
}

