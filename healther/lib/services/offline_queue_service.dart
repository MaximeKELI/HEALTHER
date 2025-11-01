import 'dart:convert';
import 'api_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  Database? _db;
  String get baseUrl => ApiService.baseUrl.replaceAll('/api', '');

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            resource TEXT NOT NULL,
            data TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            retry_count INTEGER DEFAULT 0,
            priority INTEGER DEFAULT 5,
            conflict_resolution TEXT DEFAULT 'server_wins',
            server_version INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE offline_queue ADD COLUMN priority INTEGER DEFAULT 5');
          db.execute('ALTER TABLE offline_queue ADD COLUMN conflict_resolution TEXT DEFAULT \'server_wins\'');
          db.execute('ALTER TABLE offline_queue ADD COLUMN server_version INTEGER');
          db.execute('ALTER TABLE offline_queue ADD COLUMN updated_at INTEGER');
        }
      },
    );
  }

  // Ajouter un item à la file d'attente
  Future<int> addToQueue(
    String action,
    String resource,
    Map<String, dynamic> data, {
    int priority = 5,
    String conflictResolution = 'server_wins',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(
      'offline_queue',
      {
        'action': action,
        'resource': resource,
        'data': json.encode(data),
        'status': 'pending',
        'retry_count': 0,
        'priority': priority,
        'conflict_resolution': conflictResolution,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  // Obtenir tous les items en attente (triés par priorité puis date)
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final db = await database;
    final items = await db.query(
      'offline_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, created_at ASC',
    );

    return items.map((item) {
      return {
        ...item,
        'data': json.decode(item['data'] as String),
      };
    }).toList();
  }
  
  // Résoudre un conflit lors de la sync
  Future<Map<String, dynamic>?> resolveConflict(
    Map<String, dynamic> localItem,
    Map<String, dynamic> serverItem,
  ) async {
    final resolution = localItem['conflict_resolution'] as String? ?? 'server_wins';
    
    switch (resolution) {
      case 'server_wins':
        return serverItem;
      case 'client_wins':
        return localItem['data'] as Map<String, dynamic>;
      case 'merge':
        // Merge: combiner les champs (client a priorité sur les champs existants)
        return {
          ...serverItem,
          ...localItem['data'] as Map<String, dynamic>,
        };
      default:
        return null;
    }
  }

  // Synchroniser les items en attente
  Future<void> syncQueue() async {
    final items = await getPendingItems();
    
    for (final item in items) {
      try {
        await _syncItem(item);
      } catch (e) {
        print('Erreur sync item ${item['id']}: $e');
        await _markAsFailed(item['id'] as int, e.toString());
      }
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final db = await database;
    final action = item['action'] as String;
    final resource = item['resource'] as String;
    final data = item['data'] as Map<String, dynamic>;

    // Marquer comme en cours de sync
    await db.update(
      'offline_queue',
      {'status': 'syncing'},
      where: 'id = ?',
      whereArgs: [item['id']],
    );

    // Appeler l'API correspondante
    final response = await _callAPI(action, resource, data);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Marquer comme synchronisé et supprimer
      await db.delete(
        'offline_queue',
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    } else {
      throw Exception('Erreur API: ${response.statusCode}');
    }
  }

  Future<http.Response> _callAPI(String action, String resource, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/$resource');
    
    switch (action.toLowerCase()) {
      case 'create':
      case 'post':
        return await http.post(
          uri,
          headers: ApiService().headers,
          body: json.encode(data),
        );
      case 'update':
      case 'put':
        final id = data['id'];
        return await http.put(
          Uri.parse('$uri/$id'),
          headers: ApiService().headers,
          body: json.encode(data),
        );
      default:
        throw Exception('Action non supportée: $action');
    }
  }

  Future<void> _markAsFailed(int id, String error) async {
    final db = await database;
    final item = await db.query(
      'offline_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (item.isNotEmpty) {
      final retryCount = (item.first['retry_count'] as int) + 1;
      
      await db.update(
        'offline_queue',
        {
          'status': retryCount >= 3 ? 'failed' : 'pending',
          'retry_count': retryCount,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Obtenir le statut de la file
  Future<Map<String, dynamic>> getQueueStatus() async {
    final db = await database;
    final pending = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_queue WHERE status = ?',
      ['pending'],
    );
    final failed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_queue WHERE status = ?',
      ['failed'],
    );

    return {
      'pending': pending.first['count'] as int? ?? 0,
      'failed': failed.first['count'] as int? ?? 0,
    };
  }
}

