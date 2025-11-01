import '../models/user.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUserFromStorage();
  }

  // Charger l'utilisateur depuis le stockage local
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('jwt_token');
      final refreshToken = prefs.getString('refresh_token');
      
      if (userId != null) {
        try {
          _currentUser = await _apiService.getUser(userId);
          
          // Restaurer les tokens
          if (token != null) {
            _apiService.setToken(token);
          }
          if (refreshToken != null) {
            _apiService.setRefreshToken(refreshToken);
          }
          
          notifyListeners();
        } catch (e) {
          // Si l'utilisateur n'existe plus, nettoyer les données
          print('Erreur chargement utilisateur: $e');
          await prefs.remove('user_id');
          await prefs.remove('jwt_token');
          await prefs.remove('refresh_token');
          _currentUser = null;
        }
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
    }
  }

  // Sauvegarder l'utilisateur dans le stockage local
  Future<void> _saveUserToStorage(User user, String? token, String? refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user.id != null) {
        await prefs.setInt('user_id', user.id!);
      }
      
      // Sauvegarder les tokens
      if (token != null) {
        await prefs.setString('jwt_token', token);
        _apiService.setToken(token);
      }
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
        _apiService.setRefreshToken(refreshToken);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }

  // Connexion
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      final user = response['user'] as User?;
      final token = response['token'] is String ? response['token'] as String? : null;
      final refreshToken = response['refresh_token'] is String ? response['refresh_token'] as String? : null;
      
      if (user != null) {
        _currentUser = user;
        await _saveUserToStorage(user, token, refreshToken);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors de la connexion: $e');
      return false;
    }
  }

  // Inscription
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? nom,
    String? prenom,
    String? centreSante,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        centreSante: centreSante,
      );
      
      final user = response['user'] as User?;
      final token = response['token'] is String ? response['token'] as String? : null;
      final refreshToken = response['refresh_token'] is String ? response['refresh_token'] as String? : null;
      
      if (user != null) {
        _currentUser = user;
        await _saveUserToStorage(user, token, refreshToken);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // Mettre à jour l'utilisateur
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
    _saveUserToStorage(user, _apiService.getToken(), _apiService.getRefreshToken());
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      // Révoquer le refresh token côté serveur
      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
      
      await prefs.remove('user_id');
      await prefs.remove('jwt_token');
      await prefs.remove('refresh_token');
      _currentUser = null;
      _apiService.setToken(null);
      _apiService.setRefreshToken(null);
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }
}


