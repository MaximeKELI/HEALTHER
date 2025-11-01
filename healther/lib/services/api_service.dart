import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/epidemic.dart';
import '../models/diagnostic.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // URL de base du backend API - Configuration dynamique selon l'environnement
  // Pour Android Emulator : utiliser 'http://10.0.2.2:3000/api'
  // Pour iOS Simulator : utiliser 'http://localhost:3000/api'
  // Pour appareil physique : utiliser 'http://[ADRESSE_IP_LOCALE]:3000/api'
  String _baseUrl;
  
  // Token JWT stocké
  String? _token;
  String? _refreshToken;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() : _baseUrl = _getBaseUrl();

  // Méthode statique pour obtenir l'URL de base
  static String _getBaseUrl() {
    // Utiliser une variable d'environnement si définie, sinon valeur par défaut
    const String envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Détection automatique pour Android Emulator
    return 'http://localhost:3000/api';
  }

  // Définir le token JWT
  void setToken(String? token) {
    _token = token;
  }

  // Définir le refresh token
  void setRefreshToken(String? refreshToken) {
    _refreshToken = refreshToken;
  }

  // Obtenir le token actuel
  String? getToken() => _token;

  // Obtenir le refresh token actuel
  String? getRefreshToken() => _refreshToken;

  // Headers communs avec token JWT
  Map<String, String> get _headers {
    final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Getter public pour headers (pour les autres services)
  Map<String, String> get headers => _headers;
  
  // Getter public pour baseUrl (pour les autres services)
  String get baseUrl => _baseUrl;

  // Exécuter une requête avec retry automatique après refresh (public pour les autres services)
  Future<http.Response> _executeWithRetry(Future<http.Response> Function() requestFn) async {
    http.Response response = await requestFn();
    
    // Si token expiré (401/403), tenter refresh puis retry
    if ((response.statusCode == 401 || response.statusCode == 403) && _refreshToken != null) {
      try {
        final refreshed = await refreshAccessToken(_refreshToken!);
        if (refreshed) {
          // Retry la requête avec le nouveau token
          response = await requestFn();
        }
      } catch (e) {
        // Refresh échoué, déconnexion requise
        _token = null;
        _refreshToken = null;
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Token expiré, veuillez vous reconnecter');
      }
    }
    
    // Gestion des erreurs HTTP
    await _handleError(response);
    return response;
  }

  // Gestion des erreurs HTTP
  Future<void> _handleError(http.Response response) async {
    if (response.statusCode >= 400) {
      String errorMessage = 'Erreur serveur';
      try {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur serveur';
        }
      } catch (e) {
        // Si le body n'est pas du JSON, utiliser le texte brut
        errorMessage = response.body.isNotEmpty ? response.body : 'Erreur serveur';
      }
      throw Exception(errorMessage);
    }
  }

  // Rafraîchir le token d'accès
  Future<bool> refreshAccessToken(String refreshTokenValue) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshTokenValue}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'] as String;
        _refreshToken = data['refresh_token'] as String? ?? refreshTokenValue;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout: révoquer le refresh token
  Future<void> logout(String? refreshToken) async {
    if (refreshToken != null && _token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/users/logout'),
          headers: _headers,
          body: json.encode({'refresh_token': refreshToken}),
        );
      } catch (e) {
        // Ignorer les erreurs de logout
      }
    }
    _token = null;
    _refreshToken = null;
  }

  // ========== UTILISATEURS ==========

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: _headers,
      body: json.encode({
        'username': username,
        'password': password, // Le backend attend password en clair (hashé avec bcrypt)
      }),
    );

    await _handleError(response);
    final data = json.decode(response.body);
    
    // Stocker les tokens
    if (data['token'] != null) {
      _token = data['token'] as String;
    }
    if (data['refresh_token'] != null) {
      _refreshToken = data['refresh_token'] as String;
    }
    
    final userData = data['user'] ?? data;
    if (userData == null || userData is! Map<String, dynamic>) {
      throw Exception('Données utilisateur invalides lors de la connexion');
    }
    
    return {
      'user': User.fromJson(userData),
      'token': data['token'] as String?,
      'refresh_token': data['refresh_token'] as String?,
    };
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? nom,
    String? prenom,
    String? centreSante,
    String role = 'agent',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: _headers,
      body: json.encode({
        'username': username,
        'email': email,
        'password': password, // Le backend attend password en clair (hashé avec bcrypt)
        'nom': nom,
        'prenom': prenom,
        'centre_sante': centreSante,
        'role': role,
      }),
    );

    await _handleError(response);
    final data = json.decode(response.body);
    
    // Stocker les tokens
    if (data['token'] != null) {
      _token = data['token'] as String;
    }
    if (data['refresh_token'] != null) {
      _refreshToken = data['refresh_token'] as String;
    }
    
    final userData = data['user'] ?? data;
    if (userData == null || userData is! Map<String, dynamic>) {
      throw Exception('Données utilisateur invalides lors de la connexion');
    }
    
    return {
      'user': User.fromJson(userData),
      'token': data['token'] as String?,
      'refresh_token': data['refresh_token'] as String?,
    };
  }

  Future<User> getUser(int id) async {
    final response = await _executeWithRetry(() async {
      return await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );
    });

    final data = json.decode(response.body);
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Données utilisateur invalides');
    }
    return User.fromJson(data);
  }

  // Upload photo de profil
  Future<Map<String, dynamic>> uploadProfilePicture(int userId, File imageFile) async {
    final uri = Uri.parse('$baseUrl/users/$userId/profile-picture');
    
    // Utiliser un retry simple pour MultipartRequest
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final request = http.MultipartRequest('PUT', uri);
        
        // Ajouter les headers d'autorisation
        request.headers.addAll(_headers);
        
        // Ajouter le fichier
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode >= 400) {
          await _handleError(response);
        }
        
        final data = json.decode(response.body);
        return data;
      } catch (e) {
        // Si token expiré, tenter refresh
        if (attempt == 0 && _refreshToken != null) {
          try {
            await refreshAccessToken(_refreshToken!);
            continue; // Retry avec nouveau token
          } catch (_) {
            // Refresh échoué
          }
        }
        rethrow;
      }
    }
    
    throw Exception('Échec de l\'upload après plusieurs tentatives');
  }

  // Supprimer photo de profil
  Future<void> deleteProfilePicture(int userId) async {
    final response = await _executeWithRetry(() async {
      return await http.delete(
        Uri.parse('$baseUrl/users/$userId/profile-picture'),
        headers: _headers,
      );
    });

    await _handleError(response);
  }

  // ========== DIAGNOSTICS ==========

  Future<Diagnostic> createDiagnostic(Diagnostic diagnostic) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
      Uri.parse('$baseUrl/diagnostics'),
      headers: _headers,
      body: json.encode(diagnostic.toJson()),
    );
    });

    final result = json.decode(response.body);
    return diagnostic.copyWith(id: result['id'] as int);
  }

  // Upload de diagnostic via multipart (fichier image)
  Future<int> createDiagnosticUpload({
    required File imageFile,
    required int userId,
    required String maladieType, // 'paludisme' | 'typhoide' | 'mixte'
    required String statut, // 'positif' | 'negatif' | 'incertain'
    Map<String, dynamic>? resultatIa,
    double? confiance,
    double? quantiteParasites,
    String? commentaires,
    double? latitude,
    double? longitude,
    String? adresse,
    String? region,
    String? prefecture,
  }) async {
    final uri = Uri.parse('$baseUrl/diagnostics/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['user_id'] = userId.toString();
    request.fields['maladie_type'] = maladieType;
    request.fields['statut'] = statut;
    if (resultatIa != null) request.fields['resultat_ia'] = json.encode(resultatIa);
    if (confiance != null) request.fields['confiance'] = confiance.toString();
    if (quantiteParasites != null) request.fields['quantite_parasites'] = quantiteParasites.toString();
    if (commentaires != null) request.fields['commentaires'] = commentaires;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    if (adresse != null) request.fields['adresse'] = adresse;
    if (region != null) request.fields['region'] = region;
    if (prefecture != null) request.fields['prefecture'] = prefecture;

    request.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));

    // Ajout des headers génériques si besoin (except Content-Type géré par MultipartRequest)
    request.headers['Accept'] = 'application/json';
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    final streamed = await request.send();
    var response = await http.Response.fromStream(streamed);
    
    // Retry si token expiré (pour multipart, on doit reconstruire la requête)
    if ((response.statusCode == 401 || response.statusCode == 403) && _refreshToken != null) {
      try {
        final refreshed = await refreshAccessToken(_refreshToken!);
        if (refreshed) {
          // Reconstruire la requête avec le nouveau token
          final retryRequest = http.MultipartRequest('POST', uri);
          retryRequest.fields.addAll(request.fields);
          retryRequest.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));
          retryRequest.headers['Accept'] = 'application/json';
          retryRequest.headers['Authorization'] = 'Bearer $_token';
          
          final retryStreamed = await retryRequest.send();
          response = await http.Response.fromStream(retryStreamed);
        }
      } catch (e) {
        _token = null;
        _refreshToken = null;
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Token expiré, veuillez vous reconnecter');
      }
    }
    
    await _handleError(response);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  Future<List<Diagnostic>> getDiagnostics({
    int? userId,
    String? maladieType,
    String? region,
    String? dateDebut,
    String? dateFin,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId.toString();
    if (maladieType != null) queryParams['maladie_type'] = maladieType;
    if (region != null) queryParams['region'] = region;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/diagnostics').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Diagnostic.fromJson(json)).toList();
  }

  Future<Diagnostic> getDiagnostic(int id) async {
    final response = await _executeWithRetry(() async {
      return await http.get(
      Uri.parse('$baseUrl/diagnostics/$id'),
      headers: _headers,
    );
    });

    return Diagnostic.fromJson(json.decode(response.body));
  }

  // ========== DASHBOARD ==========

  Future<Map<String, dynamic>> getStats({
    String? region,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/dashboard/stats').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    return json.decode(response.body);
  }

  Future<List<Epidemic>> getEpidemics() async {
    final response = await _executeWithRetry(() async {
      return await http.get(
      Uri.parse('$baseUrl/dashboard/epidemics'),
      headers: _headers,
    );
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Epidemic.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getMapData({
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/dashboard/map').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== ML FEEDBACK ==========
  
  Future<int> submitMLFeedback({
    required int diagnosticId,
    required bool actualResult,
    required String feedbackType,
    double? confidence,
    String? comments,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/ml-feedback'),
        headers: _headers,
        body: json.encode({
          'diagnostic_id': diagnosticId,
          'actual_result': actualResult,
          'feedback_type': feedbackType,
          'confidence': confidence,
          'comments': comments,
        }),
      );
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  // ========== SAMPLES (ÉCHANTILLONS) ==========
  
  Future<int> createSample({
    required int diagnosticId,
    String? barcode,
    String? sampleType,
    String? collectionDate,
    int? labId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/samples'),
        headers: _headers,
        body: json.encode({
          'diagnostic_id': diagnosticId,
          'barcode': barcode,
          'sample_type': sampleType,
          'collection_date': collectionDate,
          'lab_id': labId,
          'metadata': metadata,
        }),
      );
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  Future<Map<String, dynamic>> getSampleByBarcode(String barcode) async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/samples/barcode/$barcode'),
        headers: _headers,
      );
    });

    return json.decode(response.body);
  }

  // ========== COMMENTS ==========
  
  Future<int> createComment({
    required int diagnosticId,
    required String comment,
    int? parentId,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: _headers,
        body: json.encode({
          'diagnostic_id': diagnosticId,
          'comment': comment,
          'parent_id': parentId,
        }),
      );
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getDiagnosticComments(int diagnosticId) async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/comments/diagnostic/$diagnosticId'),
        headers: _headers,
      );
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== APPOINTMENTS ==========
  
  Future<int> createAppointment({
    int? diagnosticId,
    String? patientName,
    String? patientPhone,
    required String appointmentDate,
    String? notes,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: _headers,
        body: json.encode({
          'diagnostic_id': diagnosticId,
          'patient_name': patientName,
          'patient_phone': patientPhone,
          'appointment_date': appointmentDate,
          'notes': notes,
        }),
      );
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  // ========== REPORTS ==========
  
  Future<Map<String, dynamic>> generateReport({
    required String type,
    String? region,
    String? dateStart,
    String? dateEnd,
    Map<String, dynamic>? parameters,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/reports/generate'),
        headers: _headers,
        body: json.encode({
          'type': type,
          'region': region,
          'date_start': dateStart,
          'date_end': dateEnd,
          'parameters': parameters,
        }),
      );
    });

    return json.decode(response.body);
  }

  // ========== CAMPAIGNS ==========
  
  Future<int> createCampaign({
    required String name,
    required String type,
    String? region,
    String? startDate,
    String? endDate,
    String? description,
    Map<String, dynamic>? resourcesNeeded,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/campaigns'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'type': type,
          'region': region,
          'start_date': startDate,
          'end_date': endDate,
          'description': description,
          'resources_needed': resourcesNeeded,
        }),
      );
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getCampaigns({
    String? status,
    String? region,
    String? type,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (region != null) queryParams['region'] = region;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/campaigns').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== HEALTH CENTERS ==========
  
  Future<List<Map<String, dynamic>>> getHealthCenters({
    String? region,
    String? type,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/health-centers').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== TASKS ==========
  
  Future<int> createTask({
    required String title,
    String? description,
    int? diagnosticId,
    int? assignedTo,
    int priority = 5,
    String? dueDate,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _headers,
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
    });

    final data = json.decode(response.body);
    return data['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    final response = await _executeWithRetry(() async {
      return await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
    });

    await _handleError(response);
  }

  Future<List<Map<String, dynamic>>> getOverdueTasks() async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/tasks/overdue'),
        headers: _headers,
      );
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== NOTIFICATIONS ==========
  
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

    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await _executeWithRetry(() async {
      return await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: _headers,
      );
    });

    await _handleError(response);
  }

  Future<void> markAllNotificationsAsRead() async {
    final response = await _executeWithRetry(() async {
      return await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _headers,
      );
    });

    await _handleError(response);
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: _headers,
      );
    });

    final data = json.decode(response.body);
    return data['count'] as int? ?? 0;
  }

  // ========== GEOFENCING ==========
  
  Future<List<Map<String, dynamic>>> getActiveGeofences() async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/geofencing'),
        headers: _headers,
      );
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> checkGeofencingAlerts({
    String? region,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/geofencing/check-alerts')
        .replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    return json.decode(response.body);
  }

  Future<List<Map<String, dynamic>>> getGeofencingHeatmap({
    String? region,
    String? maladieType,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (maladieType != null) queryParams['maladie_type'] = maladieType;
    if (dateDebut != null) queryParams['date_debut'] = dateDebut;
    if (dateFin != null) queryParams['date_fin'] = dateFin;

    final uri = Uri.parse('$baseUrl/geofencing/heatmap')
        .replace(queryParameters: queryParams);
    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  // ========== OFFLINE QUEUE ==========
  
  Future<List<Map<String, dynamic>>> getOfflineQueueItems() async {
    final response = await _executeWithRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/offline-queue'),
        headers: _headers,
      );
    });

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<void> syncOfflineQueueItem(int itemId) async {
    final response = await _executeWithRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/offline-queue/sync/$itemId'),
        headers: _headers,
      );
    });

    await _handleError(response);
  }

  Future<void> deleteOfflineQueueItem(int itemId) async {
    final response = await _executeWithRetry(() async {
      return await http.delete(
        Uri.parse('$baseUrl/offline-queue/$itemId'),
        headers: _headers,
      );
    });

    await _handleError(response);
  }

  // ==================== PREDICTION ====================

  /// Prédire les épidémies futures
  Future<Map<String, dynamic>> predictEpidemics({
    String? region,
    String? maladieType,
    int daysAhead = 7,
    bool includeHistory = true,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (maladieType != null) queryParams['maladieType'] = maladieType;
    queryParams['daysAhead'] = daysAhead.toString();
    queryParams['includeHistory'] = includeHistory.toString();

    final uri = Uri.parse('$baseUrl/prediction/epidemics').replace(
      queryParameters: queryParams,
    );

    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final data = json.decode(response.body);
    return data;
  }

  /// Détecter les anomalies dans les données
  Future<Map<String, dynamic>> detectAnomalies({
    String? region,
    String? maladieType,
    int days = 7,
  }) async {
    final queryParams = <String, String>{};
    if (region != null) queryParams['region'] = region;
    if (maladieType != null) queryParams['maladieType'] = maladieType;
    queryParams['days'] = days.toString();

    final uri = Uri.parse('$baseUrl/prediction/anomalies').replace(
      queryParameters: queryParams,
    );

    final response = await _executeWithRetry(() async {
      return await http.get(uri, headers: _headers);
    });

    final data = json.decode(response.body);
    return data;
  }
}

// Exception personnalisée pour token expiré
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
}

// Extension pour Diagnostic.copyWith
extension DiagnosticCopyWith on Diagnostic {
  Diagnostic copyWith({
    int? id,
    int? userId,
    MaladieType? maladieType,
    String? imagePath,
    String? imageBase64,
    Map<String, dynamic>? resultatIa,
    double? confiance,
    StatutDiagnostic? statut,
    double? quantiteParasites,
    String? commentaires,
    double? latitude,
    double? longitude,
    String? adresse,
    String? region,
    String? prefecture,
    DateTime? createdAt,
  }) {
    return Diagnostic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      maladieType: maladieType ?? this.maladieType,
      imagePath: imagePath ?? this.imagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
      resultatIa: resultatIa ?? this.resultatIa,
      confiance: confiance ?? this.confiance,
      statut: statut ?? this.statut,
      quantiteParasites: quantiteParasites ?? this.quantiteParasites,
      commentaires: commentaires ?? this.commentaires,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adresse: adresse ?? this.adresse,
      region: region ?? this.region,
      prefecture: prefecture ?? this.prefecture,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

