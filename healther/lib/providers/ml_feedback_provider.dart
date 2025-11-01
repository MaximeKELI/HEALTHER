import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class MLFeedbackProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> submitFeedback({
    required int diagnosticId,
    required bool actualResult,
    required String feedbackType,
    double? confidence,
    String? comments,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.submitMLFeedback(
        diagnosticId: diagnosticId,
        actualResult: actualResult,
        feedbackType: feedbackType,
        confidence: confidence,
        comments: comments,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur soumission feedback: $e');
      return false;
    }
  }
}

