import 'dart:io';
import '../services/ocr_service.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';

/// Écran pour scanner et analyser des prescriptions médicales avec OCR
class OCRPrescriptionScreen extends StatefulWidget {
  const OCRPrescriptionScreen({super.key});

  @override
  State<OCRPrescriptionScreen> createState() => _OCRPrescriptionScreenState();
}

class _OCRPrescriptionScreenState extends State<OCRPrescriptionScreen> {
  final OCRService _ocrService = OCRService();
  final CameraService _cameraService = CameraService();
  
  File? _selectedImage;
  String? _ocrText;
  Map<String, dynamic>? _extractedInfo;
  bool _isProcessing = false;
  bool _showRawText = false;

  Future<void> _takePicture() async {
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _ocrText = null;
          _extractedInfo = null;
        });
        await _processImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur prise de photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _ocrText = null;
          _extractedInfo = null;
        });
        await _processImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sélection image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // OCR : Reconnaissance de texte
      final ocrText = await _ocrService.recognizeTextFromImageFile(_selectedImage!);
      
      // Extraction des informations structurées
      final extractedInfo = await _ocrService.extractPrescriptionInfo(ocrText);

      setState(() {
        _ocrText = ocrText;
        _extractedInfo = extractedInfo;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur traitement OCR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Prescription Médicale'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: Icon(_showRawText ? Icons.info : Icons.info_outline),
              onPressed: () {
                setState(() {
                  _showRawText = !_showRawText;
                });
              },
              tooltip: 'Afficher texte brut',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image sélectionnée
            if (_selectedImage != null)
              Card(
                elevation: 4,
                child: Image.file(
                  _selectedImage!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Traitement OCR en cours...'),
                  ],
                ),
              ),
            ],
            
            // Informations extraites
            if (_extractedInfo != null && !_showRawText) ...[
              const SizedBox(height: 20),
              const Text(
                'Informations Extraites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_extractedInfo!['patientName'] != null)
                        _buildInfoRow('Nom Patient', _extractedInfo!['patientName']),
                      if (_extractedInfo!['date'] != null)
                        _buildInfoRow('Date', _extractedInfo!['date']),
                      if (_extractedInfo!['doctorName'] != null)
                        _buildInfoRow('Médecin', _extractedInfo!['doctorName']),
                      if (_extractedInfo!['medications'] != null &&
                          (_extractedInfo!['medications'] as List).isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Médicaments:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ...(_extractedInfo!['medications'] as List<Map<String, String>>)
                            .map((med) => Padding(
                                  padding: const EdgeInsets.only(left: 10, top: 5),
                                  child: Text(
                                    '• ${med['name'] ?? ''} - ${med['dosage'] ?? ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                )),
                      ],
                      if (_extractedInfo!['instructions'] != null)
                        _buildInfoRow('Instructions', _extractedInfo!['instructions']),
                    ],
                  ),
                ),
              ),
            ],
            
            // Texte brut OCR
            if (_ocrText != null && _showRawText) ...[
              const SizedBox(height: 20),
              const Text(
                'Texte OCR Brut',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    _ocrText!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}

