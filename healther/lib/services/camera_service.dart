import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? _cameras;

  // Initialiser les caméras
  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Erreur lors de l\'initialisation des caméras: $e');
      _cameras = [];
    }
  }

  List<CameraDescription>? get cameras => _cameras;

  // Prendre une photo avec la caméra
  Future<XFile?> takePicture() async {
    try {
      await initializeCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return null;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      return photo;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Choisir une image depuis la galerie
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  // Choisir une image depuis la galerie ou la caméra
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
        );
        return image;
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        return image;
      }
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  // Convertir une image en base64
  Future<String?> imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Optionnel: redimensionner l'image pour réduire la taille
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        // Redimensionner si trop grande (max 1920px)
        img.Image resizedImage = decodedImage;
        if (decodedImage.width > 1920 || decodedImage.height > 1920) {
          final ratio = decodedImage.width > decodedImage.height
              ? 1920 / decodedImage.width
              : 1920 / decodedImage.height;
          
          resizedImage = img.copyResize(
            decodedImage,
            width: (decodedImage.width * ratio).toInt(),
            height: (decodedImage.height * ratio).toInt(),
          );
        }

        final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
        return base64Encode(resizedBytes);
      }

      // Fallback: utiliser l'image originale
      return base64Encode(bytes);
    } catch (e) {
      print('Erreur lors de la conversion en base64: $e');
      return null;
    }
  }

  // Convertir File en base64
  Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // Optionnel: redimensionner l'image
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        img.Image resizedImage = decodedImage;
        if (decodedImage.width > 1920 || decodedImage.height > 1920) {
          final ratio = decodedImage.width > decodedImage.height
              ? 1920 / decodedImage.width
              : 1920 / decodedImage.height;
          
          resizedImage = img.copyResize(
            decodedImage,
            width: (decodedImage.width * ratio).toInt(),
            height: (decodedImage.height * ratio).toInt(),
          );
        }

        final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
        return base64Encode(resizedBytes);
      }

      return base64Encode(bytes);
    } catch (e) {
      print('Erreur lors de la conversion en base64: $e');
      return null;
    }
  }

  // Analyser une image avec l'API ML réelle du backend
  Future<Map<String, dynamic>> analyzeImage(String base64Image, String maladieType) async {
    try {
      // URL de base de l'API (à configurer selon l'environnement)
      const String baseUrl = 'http://localhost:3000';
      
      // Appeler l'API ML du backend pour une analyse réelle
      final response = await http.post(
        Uri.parse('$baseUrl/api/ml/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'image_base64': base64Image,
          'maladie_type': maladieType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          return data['result'] as Map<String, dynamic>;
        } else {
          throw Exception('Erreur dans la réponse de l\'API ML');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de l\'analyse ML');
      }
    } catch (e) {
      print('Erreur lors de l\'analyse ML: $e');
      rethrow;
    }
  }
}


