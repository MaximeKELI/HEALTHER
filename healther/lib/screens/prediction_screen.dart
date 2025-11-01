import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Écran de prédiction épidémique avec visualisations
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _predictions;
  Map<String, dynamic>? _anomalies;
  bool _isLoading = false;
  String? _selectedRegion;
  String? _selectedMaladie;
  int _daysAhead = 7;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
    _loadAnomalies();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await _apiService.predictEpidemics(
        region: _selectedRegion,
        maladieType: _selectedMaladie,
        daysAhead: _daysAhead,
        includeHistory: true,
      );
      
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement prédictions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAnomalies() async {
    try {
      final anomalies = await _apiService.detectAnomalies(
        region: _selectedRegion,
        maladieType: _selectedMaladie,
        days: 7,
      );
      
      setState(() {
        _anomalies = anomalies;
      });
    } catch (e) {
      print('Erreur chargement anomalies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prédiction Épidémique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPredictions();
              _loadAnomalies();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions == null
              ? const Center(child: Text('Aucune prédiction disponible'))
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadPredictions();
                    await _loadAnomalies();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtres
                        _buildFilters(),
                        
                        const SizedBox(height: 20),
                        
                        // Informations de confiance
                        if (_predictions!['confidence'] != null)
                          _buildConfidenceCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Prédictions futures
                        if (_predictions!['predictions'] != null)
                          _buildPredictionsChart(),
                        
                        const SizedBox(height: 20),
                        
                        // Alertes d'anomalies
                        if (_anomalies != null && _anomalies!['hasAnomalies'] == true)
                          _buildAnomaliesAlert(),
                        
                        const SizedBox(height: 20),
                        
                        // Détails des prédictions
                        if (_predictions!['predictions'] != null)
                          _buildPredictionsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Région',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes')),
                      const DropdownMenuItem(value: 'Lomé', child: Text('Lomé')),
                      const DropdownMenuItem(value: 'Kara', child: Text('Kara')),
                      const DropdownMenuItem(value: 'Sokodé', child: Text('Sokodé')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _loadPredictions();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMaladie,
                    decoration: const InputDecoration(
                      labelText: 'Maladie',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes')),
                      const DropdownMenuItem(
                        value: 'paludisme',
                        child: Text('Paludisme'),
                      ),
                      const DropdownMenuItem(
                        value: 'typhoide',
                        child: Text('Typhoïde'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMaladie = value;
                      });
                      _loadPredictions();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Jours à prédire: '),
                Expanded(
                  child: Slider(
                    value: _daysAhead.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    label: '$_daysAhead jours',
                    onChanged: (value) {
                      setState(() {
                        _daysAhead = value.toInt();
                      });
                      _loadPredictions();
                    },
                  ),
                ),
                Text('$_daysAhead'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = _predictions!['confidence'] as int? ?? 0;
    final color = confidence > 70
        ? Colors.green
        : confidence > 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.insights, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confiance de la Prédiction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: confidence / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$confidence%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsChart() {
    final predictions = _predictions!['predictions'] as List<dynamic>;
    
    if (predictions.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prédictions Futures',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < predictions.length) {
                            final prediction = predictions[value.toInt()];
                            final dateStr = prediction['date'] as String? ?? '';
                            if (dateStr.isNotEmpty) {
                              final date = DateTime.tryParse(dateStr);
                              if (date != null) {
                                return Text(
                                  DateFormat('MM/dd').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: predictions.asMap().entries.map((entry) {
                        final prediction = entry.value as Map<String, dynamic>;
                        final count = prediction['predictedCount'] as int? ?? 0;
                        return FlSpot(entry.key.toDouble(), count.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesAlert() {
    final anomalies = _anomalies!['anomalies'] as List<dynamic>;
    
    return Card(
      elevation: 4,
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 30),
                const SizedBox(width: 10),
                const Text(
                  'Anomalies Détectées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...anomalies.take(3).map((anomaly) {
              final a = anomaly as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${a['date']}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${a['count']} cas (attendu: ${a['expected']})',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsList() {
    final predictions = _predictions!['predictions'] as List<dynamic>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails des Prédictions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...predictions.map((prediction) {
              final p = prediction as Map<String, dynamic>;
              final riskLevel = p['riskLevel'] as String? ?? 'low';
              final color = riskLevel == 'high'
                  ? Colors.red
                  : riskLevel == 'medium'
                      ? Colors.orange
                      : Colors.green;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: color.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(
                    _getRiskIcon(riskLevel),
                    color: color,
                  ),
                  title: Text(p['date'] as String? ?? ''),
                  subtitle: Text(
                    'Prévu: ${p['predictedCount']} cas '
                    '(${p['predictedPositive']} positifs)',
                  ),
                  trailing: Chip(
                    label: Text(riskLevel.toUpperCase()),
                    backgroundColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(color: color, fontSize: 10),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }
}

