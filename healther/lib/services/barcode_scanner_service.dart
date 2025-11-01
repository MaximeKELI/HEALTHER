import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  MobileScannerController? _controller;
  
  MobileScannerController getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    return _controller!;
  }
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
  
  /// Parse un code-barres GS1
  Map<String, String>? parseGS1Barcode(String rawData) {
    try {
      // Format GS1: (01)12345678901234(17)231231(10)ABC123
      final Map<String, String> parsed = {};
      
      // Détecter les Application Identifiers (AI) entre parenthèses
      final aiPattern = RegExp(r'\((\d{2,4})\)([^(]+)');
      final matches = aiPattern.allMatches(rawData);
      
      for (final match in matches) {
        final ai = match.group(1)!;
        final value = match.group(2)!;
        
        switch (ai) {
          case '01': // GTIN
            parsed['gtin'] = value;
            break;
          case '17': // Date d'expiration (YYMMDD)
            parsed['expiry_date'] = value;
            break;
          case '10': // Numéro de lot
            parsed['lot_number'] = value;
            break;
          case '21': // Numéro de série
            parsed['serial_number'] = value;
            break;
          case '30': // Quantité variable
            parsed['quantity'] = value;
            break;
          default:
            parsed['ai_$ai'] = value;
        }
      }
      
      return parsed.isEmpty ? null : parsed;
    } catch (e) {
      return null;
    }
  }
  
  /// Valider un code-barres selon le type
  bool validateBarcode(String data, String? format) {
    switch (format?.toLowerCase()) {
      case 'ean13':
      case 'ean8':
        return _validateEAN(data);
      case 'code128':
        return _validateCode128(data);
      case 'datamatrix':
        return data.length >= 4;
      default:
        return data.isNotEmpty;
    }
  }
  
  bool _validateEAN(String data) {
    if (data.length != 8 && data.length != 13) return false;
    
    // Vérifier que tous les caractères sont des chiffres
    if (!RegExp(r'^\d+$').hasMatch(data)) return false;
    
    // Calculer la clé de contrôle
    final digits = data.split('').map(int.parse).toList();
    final checksum = digits[digits.length - 1];
    final sum = digits.sublist(0, digits.length - 1).asMap().entries.map((e) {
      return e.value * (e.key % 2 == 0 ? 1 : 3);
    }).reduce((a, b) => a + b);
    
    final calculatedChecksum = (10 - (sum % 10)) % 10;
    return calculatedChecksum == checksum;
  }
  
  bool _validateCode128(String data) {
    // Code 128: ASCII étendu, longueur variable
    return data.isNotEmpty && data.length <= 80;
  }
}
