import 'package:flutter/material.dart';
import '../services/barcode_scanner_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String, String?) onBarcodeScanned;
  
  const BarcodeScannerScreen({super.key, required this.onBarcodeScanned});
  
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  MobileScannerController? _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }
  
  void _initializeScanner() {
    _controller = _scannerService.getController();
    _controller?.start();
    
    _controller?.barcodes.listen((barcodes) {
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
            Navigator.of(context).pop({'barcode': rawData, 'format': format, 'parsed': parsed});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code-barres invalide')),
            );
          }
        }
      }
    });
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    _scannerService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner code-barres'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            fit: BoxFit.cover,
          ),
          // Overlay avec zone de scan
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Positionnez le code-barres dans le cadre',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
