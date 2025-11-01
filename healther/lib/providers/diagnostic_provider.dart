import 'dart:io';
import '../models/diagnostic.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/offline_queue_service.dart';
import 'package:image_picker/image_picker.dart';

class DiagnosticProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final OfflineQueueService _offlineQueueService = OfflineQueueService();

  List<Diagnostic> _diagnostics = [];
  bool _isLoading = false;
  Diagnostic? _currentDiagnostic;

  List<Diagnostic> get diagnostics => _diagnostics;
  bool get isLoading => _isLoading;
  Diagnostic? get currentDiagnostic => _currentDiagnostic;

  // Créer un nouveau diagnostic
  Future<bool> createDiagnostic({
    required int userId,
    required MaladieType maladieType,
    required String imageBase64,
    Map<String, dynamic>? resultatIa,
    double? confiance,
    required StatutDiagnostic statut,
    double? quantiteParasites,
    String? commentaires,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtenir la géolocalisation
      final locationInfo = await _locationService.getLocationInfo();

      final diagnostic = Diagnostic(
        userId: userId,
        maladieType: maladieType,
        imageBase64: imageBase64,
        resultatIa: resultatIa,
        confiance: confiance,
        statut: statut,
        quantiteParasites: quantiteParasites,
        commentaires: commentaires,
        latitude: locationInfo?['latitude'] as double?,
        longitude: locationInfo?['longitude'] as double?,
        adresse: locationInfo?['adresse'] as String?,
        region: locationInfo?['region'] as String?,
        prefecture: locationInfo?['prefecture'] as String?,
      );

      await _apiService.createDiagnostic(diagnostic);
      
      // Recharger la liste des diagnostics
      await loadDiagnostics(userId: userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors de la création du diagnostic: $e');
      return false;
    }
  }

  // Créer un diagnostic via upload de fichier (multipart)
  Future<bool> createDiagnosticWithFile({
    required XFile imageFile,
    required int userId,
    required MaladieType maladieType,
    required Map<String, dynamic> analysisResult,
    String? commentaires,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtenir la géolocalisation
      final locationInfo = await _locationService.getLocationInfo();

      final statut = analysisResult['detected'] == true
          ? StatutDiagnostic.positif
          : StatutDiagnostic.negatif;

      final confiance = (analysisResult['confidence'] as num?)?.toDouble();
      final quantiteParasites = (analysisResult['parasites_count'] as num?)?.toDouble();

      final file = File(imageFile.path);

      try {
        await _apiService.createDiagnosticUpload(
          imageFile: file,
          userId: userId,
          maladieType: maladieType.name,
          statut: statut.name,
          resultatIa: analysisResult,
          confiance: confiance,
          quantiteParasites: quantiteParasites,
          commentaires: commentaires,
          latitude: locationInfo?['latitude'] as double?,
          longitude: locationInfo?['longitude'] as double?,
          adresse: locationInfo?['adresse'] as String?,
          region: locationInfo?['region'] as String?,
          prefecture: locationInfo?['prefecture'] as String?,
        );

        // Recharger la liste des diagnostics
        await loadDiagnostics(userId: userId);
      } catch (e) {
        // Si erreur réseau, ajouter à la file d'attente offline
        print('Erreur réseau - Ajout à la file d\'attente offline: $e');
        await _offlineQueueService.addToQueue(
          'create',
          'diagnostics/upload',
          {
            'user_id': userId,
            'maladie_type': maladieType.name,
            'statut': statut.name,
            'resultat_ia': analysisResult,
            'confiance': confiance,
            'quantite_parasites': quantiteParasites,
            'commentaires': commentaires,
            'latitude': locationInfo?['latitude'],
            'longitude': locationInfo?['longitude'],
            'adresse': locationInfo?['adresse'],
            'region': locationInfo?['region'],
            'prefecture': locationInfo?['prefecture'],
            // Note: L'image sera re-uploadée lors de la sync
          },
        );
        throw Exception('Erreur réseau - Diagnostic ajouté à la file d\'attente');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors de la création du diagnostic (upload): $e');
      return false;
    }
  }

  // Charger les diagnostics
  Future<void> loadDiagnostics({
    int? userId,
    String? maladieType,
    String? region,
    String? dateDebut,
    String? dateFin,
    int limit = 100,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _diagnostics = await _apiService.getDiagnostics(
        userId: userId,
        maladieType: maladieType,
        region: region,
        dateDebut: dateDebut,
        dateFin: dateFin,
        limit: limit,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors du chargement des diagnostics: $e');
    }
  }

  // Obtenir un diagnostic spécifique
  Future<void> loadDiagnostic(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentDiagnostic = await _apiService.getDiagnostic(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors du chargement du diagnostic: $e');
    }
  }

  // Analyser une image avec l'IA réelle
  Future<Map<String, dynamic>?> analyzeImage(String imageBase64, MaladieType maladieType) async {
    try {
      final maladieTypeStr = maladieType.name; // 'paludisme', 'typhoide', 'mixte'
      return await _cameraService.analyzeImage(imageBase64, maladieTypeStr);
    } catch (e) {
      print('Erreur lors de l\'analyse de l\'image: $e');
      return null;
    }
  }
}


