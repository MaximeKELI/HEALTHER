import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

/// Écran Mini-Jeux Éducatifs - Quiz interactif
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  int _score = 0;
  bool _isLoading = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    // Questions de quiz sur les maladies tropicales
    final questions = [
      {
        'question': 'Quels sont les principaux symptômes du paludisme ?',
        'answers': [
          'Fièvre, frissons, maux de tête',
          'Toux, écoulement nasal',
          'Douleurs articulaires uniquement',
          'Nausées, vomissements uniquement',
        ],
        'correct': 0,
        'explanation': 'Le paludisme se caractérise par des fièvres intermittentes, des frissons et des maux de tête.',
      },
      {
        'question': 'Comment se transmet le paludisme ?',
        'answers': [
          'Par piqûre de moustique Anopheles',
          'Par contact direct avec une personne infectée',
          'Par l\'eau contaminée',
          'Par l\'air',
        ],
        'correct': 0,
        'explanation': 'Le paludisme est transmis par la piqûre d\'un moustique Anopheles femelle infecté.',
      },
      {
        'question': 'Quels sont les symptômes de la typhoïde ?',
        'answers': [
          'Fièvre élevée, maux de tête, douleurs abdominales',
          'Éruptions cutanées uniquement',
          'Problèmes respiratoires',
          'Troubles de la vue',
        ],
        'correct': 0,
        'explanation': 'La typhoïde cause une fièvre élevée persistante, des maux de tête et des douleurs abdominales.',
      },
      {
        'question': 'Quelle est la méthode de prévention du paludisme ?',
        'answers': [
          'Moustiquaires imprégnées, médicaments préventifs',
          'Vaccination uniquement',
          'Éviter les contacts humains',
          'Aucune prévention possible',
        ],
        'correct': 0,
        'explanation': 'La prévention du paludisme inclut les moustiquaires imprégnées et les médicaments préventifs.',
      },
      {
        'question': 'Quel est le traitement du paludisme ?',
        'answers': [
          'Médicaments antipaludiques (ACT)',
          'Antibiotiques uniquement',
          'Traitement à base de plantes uniquement',
          'Pas de traitement disponible',
        ],
        'correct': 0,
        'explanation': 'Le paludisme se traite avec des médicaments antipaludiques comme les ACT (Artemisinin-based Combination Therapy).',
      },
    ];

    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _selectAnswer(int index) {
    if (_showResult) return;

    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    setState(() {
      _showResult = true;
      
      if (_selectedAnswer == _questions[_currentQuestionIndex]['correct']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      // Quiz terminé
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final percentage = (_score / _questions.length * 100).round();
    
    // Ajouter des points de gamification
    try {
      final gamification = Provider.of<GamificationProvider>(context, listen: false);
      gamification.addFeedbackPoints(points: percentage ~/ 20); // 1 point par 20% de réussite
    } catch (e) {
      print('Erreur gamification: $e');
    }

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Terminé !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score / ${_questions.length}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('${percentage}% de bonnes réponses'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetQuiz();
            },
            child: const Text('Recommencer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _score = 0;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == question['correct'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Éducatif'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Score: $_score / ${_questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progression
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text(
              'Question ${_currentQuestionIndex + 1} / ${_questions.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            
            const SizedBox(height: 30),
            
            // Question
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Réponses
            Expanded(
              child: ListView.builder(
                itemCount: (question['answers'] as List).length,
                itemBuilder: (context, index) {
                  final answer = (question['answers'] as List)[index];
                  final isSelected = _selectedAnswer == index;
                  Color? backgroundColor;
                  
                  if (_showResult) {
                    if (index == question['correct']) {
                      backgroundColor = Colors.green.withOpacity(0.2);
                    } else if (isSelected && index != question['correct']) {
                      backgroundColor = Colors.red.withOpacity(0.2);
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: backgroundColor,
                    child: ListTile(
                      title: Text(answer),
                      leading: isSelected
                          ? Icon(
                              _showResult && index == question['correct']
                                  ? Icons.check_circle
                                  : _showResult
                                      ? Icons.cancel
                                      : Icons.radio_button_checked,
                              color: _showResult && index == question['correct']
                                  ? Colors.green
                                  : _showResult
                                      ? Colors.red
                                      : Colors.blue,
                            )
                          : const Icon(Icons.radio_button_unchecked),
                      onTap: () => _selectAnswer(index),
                    ),
                  );
                },
              ),
            ),
            
            if (_showResult) ...[
              Card(
                color: isCorrect
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCorrect ? 'Bonne réponse !' : 'Mauvaise réponse',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(question['explanation'] ?? ''),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            
            // Bouton suivant
            ElevatedButton(
              onPressed: _showResult
                  ? _nextQuestion
                  : (_selectedAnswer != null ? _submitAnswer : null),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                _showResult
                    ? (_currentQuestionIndex < _questions.length - 1
                        ? 'Question Suivante'
                        : 'Terminer le Quiz')
                    : 'Valider',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

