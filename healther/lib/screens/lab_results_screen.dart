import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Écran Visualisation Complète des Résultats de Laboratoire
class LabResultsScreen extends StatefulWidget {
  final int? diagnosticId;
  final Map<String, dynamic>? labData;

  const LabResultsScreen({
    super.key,
    this.diagnosticId,
    this.labData,
  });

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _labResults;
  List<Map<String, dynamic>>? _historicalResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.labData != null) {
      _labResults = widget.labData;
    } else {
      _loadLabResults();
    }
  }

  Future<void> _loadLabResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les résultats de laboratoire
      // TODO: Implémenter l'API pour récupérer les résultats labo
      // Pour l'instant, utiliser les données du diagnostic
      
      if (widget.diagnosticId != null) {
        final diagnostic = await _apiService.getDiagnostic(widget.diagnosticId!);
        setState(() {
          _labResults = _parseLabData(diagnostic);
        });
      }

      // Charger l'historique pour graphiques temporels
      _loadHistoricalResults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement résultats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseLabData(Map<String, dynamic> diagnostic) {
    // Parser les données labo depuis le diagnostic
    // En production, cela viendrait d'une table dédiée
    return {
      'diagnostic_id': diagnostic['id'],
      'date': diagnostic['created_at'],
      'values': [
        {
          'name': 'Hémoglobine',
          'value': 12.5,
          'unit': 'g/dL',
          'normal_min': 12.0,
          'normal_max': 16.0,
          'status': 'normal'
        },
        {
          'name': 'Hématocrite',
          'value': 38.0,
          'unit': '%',
          'normal_min': 36.0,
          'normal_max': 46.0,
          'status': 'normal'
        },
        {
          'name': 'Parasites',
          'value': 500,
          'unit': '/μL',
          'normal_min': 0,
          'normal_max': 0,
          'status': 'abnormal'
        },
      ]
    };
  }

  Future<void> _loadHistoricalResults() async {
    try {
      // Charger l'historique des résultats pour graphiques temporels
      final diagnostics = await _apiService.getDiagnostics();
      final historical = diagnostics
          .where((d) => d['created_at'] != null)
          .map((d) => _parseLabData(d))
          .toList();
      
      setState(() {
        _historicalResults = historical;
      });
    } catch (e) {
      print('Erreur chargement historique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de Laboratoire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Export PDF
            },
            tooltip: 'Exporter PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Partage sécurisé
            },
            tooltip: 'Partager',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _labResults == null
              ? const Center(child: Text('Aucun résultat disponible'))
              : RefreshIndicator(
                  onRefresh: _loadLabResults,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec date
                        _buildHeader(),
                        
                        const SizedBox(height: 20),
                        
                        // Valeurs avec comparaison aux normes
                        if (_labResults!['values'] != null)
                          _buildLabValues(_labResults!['values']),
                        
                        const SizedBox(height: 20),
                        
                        // Graphiques temporels
                        if (_historicalResults != null && _historicalResults!.isNotEmpty)
                          _buildTemporalCharts(),
                        
                        const SizedBox(height: 20),
                        
                        // Interprétation automatique
                        _buildInterpretation(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date', _labResults!['date'] ?? 'N/A'),
            _buildInfoRow('ID Diagnostic', _labResults!['diagnostic_id']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildLabValues(List<dynamic> values) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valeurs de Laboratoire',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...values.map((value) => _buildValueCard(value)),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(Map<String, dynamic> value) {
    final name = value['name'] ?? 'N/A';
    final val = value['value'] ?? 0.0;
    final unit = value['unit'] ?? '';
    final normalMin = value['normal_min'] ?? 0.0;
    final normalMax = value['normal_max'] ?? 0.0;
    final status = value['status'] ?? 'unknown';
    
    final isAbnormal = status == 'abnormal' || val < normalMin || val > normalMax;
    final statusColor = isAbnormal ? Colors.red : Colors.green;
    final statusIcon = isAbnormal ? Icons.warning : Icons.check_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${val.toStringAsFixed(2)} $unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 24),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valeurs normales: ${normalMin.toStringAsFixed(2)} - ${normalMax.toStringAsFixed(2)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isAbnormal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ANORMAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (normalMin > 0 && normalMax > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (val - normalMin) / (normalMax - normalMin),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalCharts() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution Temporelle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _historicalResults!
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key.toDouble();
                            final data = entry.value;
                            final firstValue = data['values']?[0];
                            return FlSpot(index, firstValue?['value']?.toDouble() ?? 0.0);
                          })
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildInterpretation() {
    final abnormalValues = (_labResults!['values'] as List<dynamic>?)
        ?.where((v) => v['status'] == 'abnormal')
        .toList() ?? [];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Interprétation Automatique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (abnormalValues.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Toutes les valeurs sont dans les limites normales',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...abnormalValues.map((value) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ ${value['name']} anormale',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Valeur: ${value['value']} ${value['unit']} (Normal: ${value['normal_min']}-${value['normal_max']})',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

