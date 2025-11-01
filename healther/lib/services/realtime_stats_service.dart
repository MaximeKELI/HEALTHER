import 'dart:async';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Service pour les statistiques en temps réel via WebSocket
class RealtimeStatsService with ChangeNotifier {
  static final RealtimeStatsService _instance = RealtimeStatsService._internal();
  factory RealtimeStatsService() => _instance;
  RealtimeStatsService._internal();

  String get baseUrl => ApiService.baseUrl.replaceAll('/api', '');
  IO.Socket? _socket;
  Timer? _pollTimer;
  
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _timeSeries = []; // Données pour graphiques temporels
  bool _isConnected = false;

  Map<String, dynamic>? get stats => _stats;
  List<Map<String, dynamic>> get timeSeries => _timeSeries;
  bool get isConnected => _isConnected;

  /// Connecter au WebSocket pour les stats temps réel
  void connectSocket(String? token) {
    if (_socket != null && _socket!.connected) return;
    if (token == null) return;

    try {
      _socket = IO.io(
        baseUrl.replaceFirst('http://', 'ws://'),
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        notifyListeners();
        _socket!.emit('subscribe-stats');
      });

      _socket!.on('stats-update', (data) {
        _stats = data as Map<String, dynamic>?;
        _addToTimeSeries(data);
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onError((error) {
        print('Erreur WebSocket stats: $error');
      });
    } catch (e) {
      print('Erreur connexion WebSocket stats: $e');
    }
  }

  /// Polling pour les stats si WebSocket n'est pas disponible
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => fetchStats());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchStats() async {
    try {
      final apiService = ApiService();
      final stats = await apiService.getStats();
      _stats = stats;
      _addToTimeSeries(stats);
      notifyListeners();
    } catch (e) {
      print('Erreur fetch stats: $e');
    }
  }

  void _addToTimeSeries(Map<String, dynamic>? stats) {
    if (stats == null) return;
    
    final now = DateTime.now();
    final entry = {
      'timestamp': now,
      'total': stats['global']?['total'] ?? 0,
      'positifs': stats['global']?['positifs'] ?? 0,
      'negatifs': stats['global']?['negatifs'] ?? 0,
      'taux_positivite': stats['global']?['taux_positivite'] ?? 0.0,
    };

    _timeSeries.add(entry);
    
    // Garder seulement les 30 dernières entrées (30 minutes si polling toutes les minutes)
    if (_timeSeries.length > 30) {
      _timeSeries.removeAt(0);
    }
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
    stopPolling();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}

