import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  String get baseUrl => ApiService.baseUrl;

  /// Créer une tâche
  Future<int> createTask({
    required String title,
    String? description,
    int? diagnosticId,
    int? assignedTo,
    int priority = 5,
    String? dueDate,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: ApiService().headers,
      body: json.encode({
        'title': title,
        'description': description,
        'diagnostic_id': diagnosticId,
        'assigned_to': assignedTo,
        'priority': priority,
        'due_date': dueDate,
        'metadata': metadata ?? {},
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création tâche');
    }

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  /// Obtenir les tâches de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserTasks({String? status}) async {
    final queryParams = status != null ? <String, String>{'status': status} : <String, String>{};
    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: ApiService().headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur récupération tâches');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  /// Mettre à jour le statut d'une tâche
  Future<void> updateTaskStatus(int taskId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/status'),
      headers: ApiService().headers,
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour tâche');
    }
  }
}
