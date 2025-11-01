import 'dart:io';
import 'api_service.dart';
import 'offline_queue_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service avancé pour la synchronisation offline avec compression intelligente
class OfflineSyncService with ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final OfflineQueueService _offlineQueue = OfflineQueueService();
  final ApiService _apiService = ApiService();

  bool _isSyncing = false;
  int _pendingItems = 0;
  int _syncedItems = 0;
  int _failedItems = 0;
  double _syncProgress = 0.0;

  bool get isSyncing => _isSyncing;
  int get pendingItems => _pendingItems;
  int get syncedItems => _syncedItems;
  int get failedItems => _failedItems;
  double get syncProgress => _syncProgress;

  /// Compresser une image pour économiser de l'espace et des données
  Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final originalSize = await imageFile.length();
        final compressedSize = await result.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);
        
        print('Image compressée: ${(originalSize / 1024).toStringAsFixed(2)}KB → ${(compressedSize / 1024).toStringAsFixed(2)}KB (${compressionRatio.toStringAsFixed(1)}% économisé)');
        
        return File(result.path);
      }
    } catch (e) {
      print('Erreur compression image: $e');
    }
    return null;
  }

  /// Synchroniser tous les items en attente
  Future<void> syncAll({bool compressImages = true}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncProgress = 0.0;
    _failedItems = 0;
    _syncedItems = 0;
    notifyListeners();

    try {
      final items = await _offlineQueue.getPendingItems();
      _pendingItems = items.length;

      if (items.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        try {
          // Si c'est un upload d'image, compresser si nécessaire
          if (compressImages && item['resource'] == 'diagnostics' && item['action'] == 'upload') {
            final data = item['data'] as Map<String, dynamic>?;
            if (data != null && data['image_path'] != null) {
              final imageFile = File(data['image_path'] as String);
              if (await imageFile.exists()) {
                final compressed = await compressImage(imageFile);
                if (compressed != null) {
                  data['image_path'] = compressed.path;
                  data['compressed'] = true;
                }
              }
            }
          }

          // Synchroniser l'item
          await _syncItem(item);
          _syncedItems++;
        } catch (e) {
          _failedItems++;
          print('Erreur sync item ${item['id']}: $e');
        }

        _syncProgress = (i + 1) / items.length;
        notifyListeners();
      }

      // Les items synchronisés seront supprimés automatiquement
      // par le service offline_queue lors du prochain sync

    } catch (e) {
      print('Erreur sync globale: $e');
    } finally {
      _isSyncing = false;
      _pendingItems = 0;
      notifyListeners();
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final resource = item['resource'] as String;
    final data = item['data'] as Map<String, dynamic>;

    // Utiliser l'API service pour synchroniser
    switch (resource) {
      case 'diagnostics':
        if (action == 'create' || action == 'upload') {
          // TODO: Appeler l'API de création de diagnostic
          // await _apiService.createDiagnostic(...);
        }
        break;
      case 'comments':
        if (action == 'create') {
          await _apiService.createComment(
            diagnosticId: data['diagnostic_id'] as int,
            comment: data['comment'] as String,
          );
        }
        break;
      // Ajouter d'autres ressources selon besoin
    }
  }

  /// Charger le cache prédictif des données nécessaires
  Future<void> preloadCache() async {
    try {
      // Précharger les stats du dashboard
      await _apiService.getStats();
      
      // Précharger les diagnostics récents de l'utilisateur
      // await _apiService.getDiagnostics(limit: 20);
    } catch (e) {
      print('Erreur preload cache: $e');
    }
  }

  /// Obtenir la taille du cache offline
  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Nettoyer le cache
  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File && entity.path.contains('compressed')) {
          await entity.delete();
        }
      }
    } catch (e) {
      print('Erreur nettoyage cache: $e');
    }
  }
}

