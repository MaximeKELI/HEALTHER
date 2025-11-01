import 'dart:io';
import '../models/diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/camera_service.dart';
import '../providers/diagnostic_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/gamification_provider.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final CameraService _cameraService = CameraService();
  XFile? _selectedImage;
  String? _imageBase64;
  Map<String, dynamic>? _analysisResult;
  MaladieType _selectedMaladie = MaladieType.paludisme;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;

  Future<void> _takePicture() async {
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageBase64 = null;
          _analysisResult = null;
        });
        await _convertImageToBase64();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prise de photo: $e'),
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
          _selectedImage = image;
          _imageBase64 = null;
          _analysisResult = null;
        });
        await _convertImageToBase64();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _convertImageToBase64() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final base64 = await _cameraService.imageToBase64(_selectedImage!);
      setState(() {
        _imageBase64 = base64;
      });

      // Analyser l'image avec l'IA réelle (envoi au backend ML)
      if (base64 != null) {
        final diagnosticProvider = Provider.of<DiagnosticProvider>(context, listen: false);
        final result = await diagnosticProvider.analyzeImage(base64, _selectedMaladie);
        setState(() {
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la conversion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submitDiagnostic() async {
    if (_selectedImage == null || _analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord prendre et analyser une image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final diagnosticProvider = Provider.of<DiagnosticProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préférer l'upload fichier si disponible (réaliste, sans base64)
      final success = await diagnosticProvider.createDiagnosticWithFile(
        imageFile: _selectedImage!,
        userId: user.id!,
        maladieType: _selectedMaladie,
        analysisResult: _analysisResult!,
        commentaires: null,
      );

      if (!mounted) return;

      if (success) {
        // Ajouter des points de gamification
        try {
          final gamification = Provider.of<GamificationProvider>(context, listen: false);
          gamification.addDiagnosticPoints(points: 10);
        } catch (e) {
          print('Erreur gamification: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostic enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        setState(() {
          _selectedImage = null;
          _imageBase64 = null;
          _analysisResult = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement du diagnostic'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélection du type de maladie
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de maladie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MaladieType>(
                      value: _selectedMaladie,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: MaladieType.paludisme,
                          child: Text('Paludisme'),
                        ),
                        DropdownMenuItem(
                          value: MaladieType.typhoide,
                          child: Text('Fièvre Typhoïde'),
                        ),
                        DropdownMenuItem(
                          value: MaladieType.mixte,
                          child: Text('Mixte'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMaladie = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sélection d'image
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image du diagnostic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre une photo'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isAnalyzing) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Analyse en cours...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Résultats de l'analyse
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: (_analysisResult!['detected'] == true)
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (_analysisResult!['detected'] == true)
                                ? Icons.warning
                                : Icons.check_circle,
                            color: (_analysisResult!['detected'] == true)
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (_analysisResult!['detected'] == true)
                                ? 'Résultat: POSITIF'
                                : 'Résultat: NÉGATIF',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (_analysisResult!['detected'] == true)
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confiance: ${(_analysisResult!['confidence'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
                      ),
                      if (_analysisResult!['parasites_count'] != null)
                        Text(
                          'Quantité de parasites: ${(_analysisResult!['parasites_count'] as num?)?.toStringAsFixed(0) ?? 'N/A'}',
                        ),
                      // Afficher les métadonnées ML si disponibles
                      if (_analysisResult!['details'] != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const Text(
                          'Détails de l\'analyse:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (_analysisResult!['details']['quality_score'] != null)
                          Text(
                            'Qualité: ${(_analysisResult!['details']['quality_score'] as num?)?.toStringAsFixed(0) ?? 'N/A'}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (_analysisResult!['details']['cell_count'] != null)
                          Text(
                            'Cellules: ${(_analysisResult!['details']['cell_count'] as num?)?.toStringAsFixed(0) ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (_analysisResult!['details']['parasite_ratio'] != null)
                          Text(
                            'Ratio parasites: ${(_analysisResult!['details']['parasite_ratio'] as num?)?.toStringAsFixed(2) ?? 'N/A'}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                      // Afficher les métadonnées d'analyse si disponibles (analysis_metadata)
                      if (_analysisResult!['analysis_metadata'] != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const Text(
                          'Métadonnées techniques:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (_analysisResult!['analysis_metadata']['resolution'] != null)
                          Text(
                            'Résolution: ${_analysisResult!['analysis_metadata']['resolution']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        if (_analysisResult!['analysis_metadata']['contrast'] != null)
                          Text(
                            'Contraste: ${(_analysisResult!['analysis_metadata']['contrast'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        if (_analysisResult!['analysis_metadata']['sharpness'] != null)
                          Text(
                            'Netteté: ${(_analysisResult!['analysis_metadata']['sharpness'] as num?)?.toStringAsFixed(0) ?? 'N/A'}%',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        if (_analysisResult!['analysis_metadata']['provider'] != null)
                          Text(
                            'Provider: ${_analysisResult!['analysis_metadata']['provider']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDiagnostic,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer le diagnostic'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


