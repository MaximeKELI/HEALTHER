import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Service pour la reconnaissance de texte (OCR) - Scan de prescriptions
class OCRService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  /// Scanner du texte depuis une image
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Erreur reconnaissance OCR: $e');
      rethrow;
    }
  }

  /// Scanner du texte depuis un fichier XFile
  Future<String> recognizeTextFromFile(XFile file) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Erreur reconnaissance OCR depuis fichier: $e');
      rethrow;
    }
  }

  /// Scanner du texte depuis une image File
  Future<String> recognizeTextFromImageFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Erreur reconnaissance OCR depuis image File: $e');
      rethrow;
    }
  }

  /// Extraire les informations structurées d'une prescription
  Future<Map<String, dynamic>> extractPrescriptionInfo(String ocrText) async {
    try {
      // Analyser le texte OCR pour extraire les informations structurées
      final lines = ocrText.split('\n');
      
      String? patientName;
      String? date;
      List<Map<String, String>> medications = [];
      String? doctorName;
      String? instructions;

      // Recherche du nom du patient (généralement au début)
      for (final line in lines) {
        if (line.toLowerCase().contains('patient') ||
            line.toLowerCase().contains('nom')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            patientName = parts[1].trim();
          }
        }
        
        // Recherche de la date
        if (line.toLowerCase().contains('date') ||
            RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(line)) {
          final dateMatch = RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').firstMatch(line);
          if (dateMatch != null) {
            date = dateMatch.group(0);
          }
        }
        
        // Recherche des médicaments (généralement avec dosage)
        if (RegExp(r'\d+\s*(mg|ml|g|cp|comprimé)', caseSensitive: false)
            .hasMatch(line)) {
          final medMatch = RegExp(r'(.+?)\s*(\d+\s*(?:mg|ml|g|cp|comprimé))',
                  caseSensitive: false)
              .firstMatch(line);
          if (medMatch != null) {
            medications.add({
              'name': medMatch.group(1)?.trim() ?? '',
              'dosage': medMatch.group(2)?.trim() ?? '',
            });
          }
        }
        
        // Recherche du nom du docteur
        if (line.toLowerCase().contains('docteur') ||
            line.toLowerCase().contains('dr') ||
            line.toLowerCase().contains('médecin')) {
          doctorName = line
              .replaceAll(RegExp(r'(docteur|dr|médecin):?', caseSensitive: false), '')
              .trim();
        }
        
        // Instructions générales
        if (line.toLowerCase().contains('instruction') ||
            line.toLowerCase().contains('posologie') ||
            line.toLowerCase().contains('note')) {
          instructions = line;
        }
      }

      return {
        'patientName': patientName,
        'date': date,
        'medications': medications,
        'doctorName': doctorName,
        'instructions': instructions,
        'rawText': ocrText,
      };
    } catch (e) {
      print('Erreur extraction prescription: $e');
      return {
        'rawText': ocrText,
        'error': e.toString(),
      };
    }
  }

  /// Scanner une prescription complète (OCR + extraction)
  Future<Map<String, dynamic>> scanPrescription(String imagePath) async {
    try {
      final ocrText = await recognizeText(imagePath);
      final extractedInfo = await extractPrescriptionInfo(ocrText);
      
      return extractedInfo;
    } catch (e) {
      print('Erreur scan prescription: $e');
      rethrow;
    }
  }

  /// Libérer les ressources
  Future<void> dispose() async {
    // OCR non disponible sur Linux desktop
    if (Platform.isLinux) {
      return;
    }
    
    try {
      await _textRecognizer.close();
    } catch (e) {
      print('Erreur dispose OCR: $e');
    }
  }
}

