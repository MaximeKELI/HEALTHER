import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/barcode_scanner_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String, String?) onBarcodeScanned;
  
  const BarcodeScannerScreen({super.key, required this.onBarcodeScanned});
  
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  bool _isInitialized = false;
  bool _isLinux = Platform.isLinux;
  
  @override
  void initState() {
    super.initState();
    if (!_isLinux) {
      _initializeScanner();
    } else {
      _isInitialized = true;
    }
  }
  
  void _initializeScanner() {
    if (_isLinux) return;
    
    try {
      final controller = _scannerService.getController();
      if (controller != null) {
        controller.start();
        
        controller.barcodes.listen((barcodes) {
          if (barcodes.barcodes.isNotEmpty) {
            final barcode = barcodes.barcodes.first;
            final rawData = barcode.rawValue;
            final format = barcode.type.name;
            
            if (rawData != null) {
              // Valider le code-barres
              if (_scannerService.validateBarcode(rawData, format)) {
                // Parser GS1 si possible
                final parsed = _scannerService.parseGS1Barcode(rawData);
                
                widget.onBarcodeScanned(rawData, format);
                if (mounted) {
                  Navigator.of(context).pop({'barcode': rawData, 'format': format, 'parsed': parsed});
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code-barres invalide')),
                  );
                }
              }
            }
          }
        });
        
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur initialisation scanner: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    if (!_isLinux) {
      try {
        final controller = _scannerService.getController();
        controller?.stop();
        controller?.dispose();
        _scannerService.dispose();
      } catch (e) {
        print('Erreur dispose scanner: $e');
      }
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLinux) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner code-barres'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Scanner non disponible sur Linux',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le scanner de code-barres nécessite une caméra\nqui n\'est pas disponible sur Linux desktop.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Simuler un scan pour les tests
                  widget.onBarcodeScanned('TEST123', 'ean13');
                  Navigator.of(context).pop({'barcode': 'TEST123', 'format': 'ean13'});
                },
                child: const Text('Simuler un scan (test)'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return const Scaffold(
        appBar: AppBar(title: Text('Scanner code-barres')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Pour mobile, utiliser le widget MobileScanner
    // Note: Sur Linux, on ne devrait jamais arriver ici
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner code-barres'),
      ),
      body: const Center(
        child: Text('Scanner non disponible sur cette plateforme'),
      ),
    );
  }
}
