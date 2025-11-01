import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/report_service.dart';

/// Écran Analytics Avancé avec Rapports PDF/Excel
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  final ReportService _reportService = ReportService();
  
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _selectedRegion;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _apiService.getStats(
        region: _selectedRegion,
        dateDebut: _startDate?.toIso8601String().split('T')[0],
        dateFin: _endDate?.toIso8601String().split('T')[0],
      );
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePDFReport() async {
    if (_stats == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final pdfFile = await _reportService.generateStatsPDF(
        stats: _stats!,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Partager le PDF
      await _reportService.shareReport(pdfFile, subject: 'Rapport HEALTHER');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport PDF généré et partagé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateExcelReport() async {
    if (_stats == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Convertir stats en format Excel
      final data = _convertStatsToExcelFormat(_stats!);

      final excelFile = await _reportService.generateExcelReport(
        title: 'Statistiques HEALTHER',
        data: data,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Partager le fichier Excel
      await _reportService.shareReport(excelFile, subject: 'Rapport Excel HEALTHER');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport Excel généré et partagé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _convertStatsToExcelFormat(Map<String, dynamic> stats) {
    final data = <Map<String, dynamic>>[];

    // Statistiques globales
    if (stats['global'] != null) {
      final global = stats['global'] as Map<String, dynamic>;
      global.forEach((key, value) {
        data.add({
          'Catégorie': 'Global',
          'Métrique': key,
          'Valeur': value.toString(),
        });
      });
    }

    // Statistiques par région
    if (stats['parRegion'] != null) {
      final parRegion = stats['parRegion'] as Map<String, dynamic>;
      parRegion.forEach((region, statsRegion) {
        if (statsRegion is Map<String, dynamic>) {
          statsRegion.forEach((key, value) {
            data.add({
              'Région': region,
              'Métrique': key,
              'Valeur': value.toString(),
            });
          });
        }
      });
    }

    return data;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Avancé'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _selectDateRange,
            tooltip: 'Filtrer par date',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') {
                _generatePDFReport();
              } else if (value == 'excel') {
                _generateExcelReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Aucune statistique disponible'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistiques globales
                        if (_stats!['global'] != null)
                          _buildStatsCard(
                            'Statistiques Globales',
                            _stats!['global'] as Map<String, dynamic>,
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Graphiques
                        _buildCharts(),
                        
                        const SizedBox(height: 20),
                        
                        // Statistiques par région
                        if (_stats!['parRegion'] != null)
                          _buildRegionStats(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsCard(String title, Map<String, dynamic> stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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

  Widget _buildCharts() {
    if (_stats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Graphiques',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Graphique en barres pour diagnostics par maladie
        if (_stats!['parMaladie'] != null)
          SizedBox(
            height: 250,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final maladies = _stats!['parMaladie'] as Map<String, dynamic>;
                            final maladieNames = maladies.keys.toList();
                            if (value.toInt() < maladieNames.length) {
                              return Text(
                                maladieNames[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
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
                    barGroups: _buildBarGroups(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_stats == null || _stats!['parMaladie'] == null) return [];

    final maladies = _stats!['parMaladie'] as Map<String, dynamic>;
    return maladies.entries.map((entry) {
      final index = maladies.keys.toList().indexOf(entry.key);
      final count = entry.value is num ? entry.value.toDouble() : 0.0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            color: Colors.blue,
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildRegionStats() {
    final parRegion = _stats!['parRegion'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques par Région',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...parRegion.entries.map((entry) {
          if (entry.value is Map<String, dynamic>) {
            return _buildStatsCard(
              entry.key,
              entry.value as Map<String, dynamic>,
            );
          }
          return const SizedBox();
        }),
      ],
    );
  }
}

