import '../models/diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ml_feedback_provider.dart';

class MLFeedbackScreen extends StatefulWidget {
  final Diagnostic diagnostic;

  const MLFeedbackScreen({super.key, required this.diagnostic});

  @override
  State<MLFeedbackScreen> createState() => _MLFeedbackScreenState();
}

class _MLFeedbackScreenState extends State<MLFeedbackScreen> {
  String? _selectedFeedbackType;
  bool? _actualResult;
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedFeedbackType == null || _actualResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<MLFeedbackProvider>(context, listen: false);
    
    final success = await provider.submitFeedback(
      diagnosticId: widget.diagnostic.id!,
      actualResult: _actualResult!,
      feedbackType: _selectedFeedbackType!,
      confidence: widget.diagnostic.confiance,
      comments: _commentsController.text.isNotEmpty
          ? _commentsController.text
          : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictedResult = widget.diagnostic.resultatIa?['detected'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback ML'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat prédit par l\'IA:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      predictedResult ? 'POSITIF' : 'NÉGATIF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: predictedResult ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      'Confiance: ${widget.diagnostic.confiance?.toStringAsFixed(1) ?? 'N/A'}%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat réel:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Positif'),
                            value: true,
                            groupValue: _actualResult,
                            onChanged: (value) {
                              setState(() => _actualResult = value);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Négatif'),
                            value: false,
                            groupValue: _actualResult,
                            onChanged: (value) {
                              setState(() => _actualResult = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de feedback:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFeedbackType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Sélectionner',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'correct',
                          child: Text('Correct'),
                        ),
                        DropdownMenuItem(
                          value: 'incorrect',
                          child: Text('Incorrect'),
                        ),
                        DropdownMenuItem(
                          value: 'uncertain',
                          child: Text('Incertain'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFeedbackType = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Consumer<MLFeedbackProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Envoyer le feedback'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

