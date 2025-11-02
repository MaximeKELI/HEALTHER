import '../services/api_service.dart';
import 'package:flutter/material.dart';

/// Écran Dashboard Patient Personnel - Vue simplifiée pour les patients
class DashboardPatientScreen extends StatefulWidget {
  const DashboardPatientScreen({super.key});

  @override
  State<DashboardPatientScreen> createState() => _DashboardPatientScreenState();
}

class _DashboardPatientScreenState extends State<DashboardPatientScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _patientStats;
  List<Map<String, dynamic>>? _recentDiagnostics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les diagnostics du patient
      final diagnostics = await _apiService.getDiagnostics();
      
      // Convertir les objets Diagnostic en Map
      final diagnosticsMap = diagnostics.map((d) => d.toJson()).toList();
      
      // Calculer les statistiques personnelles
      final stats = _calculateStats(diagnostics);
      
      setState(() {
        _recentDiagnostics = diagnosticsMap.take(5).toList();
        _patientStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement données: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _calculateStats(List<dynamic> diagnostics) {
    final total = diagnostics.length;
    final positif = diagnostics.where((d) {
      if (d is Map) return d['statut'] == 'positif';
      return d.statut.name == 'positif';
    }).length;
    final negatif = diagnostics.where((d) {
      if (d is Map) return d['statut'] == 'negatif';
      return d.statut.name == 'negatif';
    }).length;
    final paludisme = diagnostics.where((d) {
      if (d is Map) return d['maladie_type'] == 'paludisme';
      return d.maladieType.name == 'paludisme';
    }).length;
    final typhoide = diagnostics.where((d) {
      if (d is Map) return d['maladie_type'] == 'typhoide';
      return d.maladieType.name == 'typhoide';
    }).length;

    return {
      'total_diagnostics': total,
      'positif': positif,
      'negatif': negatif,
      'paludisme': paludisme,
      'typhoide': typhoide,
      'taux_positivite': total > 0 ? (positif / total * 100).toStringAsFixed(1) : '0',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatientData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques personnelles
                    if (_patientStats != null) _buildPersonalStats(),

                    const SizedBox(height: 20),

                    // Objectifs de santé
                    _buildHealthGoals(),

                    const SizedBox(height: 20),

                    // Diagnostics récents
                    if (_recentDiagnostics != null && _recentDiagnostics!.isNotEmpty)
                      _buildRecentDiagnostics(),

                    const SizedBox(height: 20),

                    // Actions rapides
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPersonalStats() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Statistiques de Santé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total',
                  _patientStats!['total_diagnostics'].toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Positifs',
                  _patientStats!['positif'].toString(),
                  Colors.red,
                ),
                _buildStatCard(
                  'Négatifs',
                  _patientStats!['negatif'].toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  'Taux',
                  '${_patientStats!['taux_positivite']}%',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthGoals() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Objectifs de Santé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalItem(
              'Pas d\'épidémie',
              'Rester en bonne santé pendant 30 jours',
              Icons.favorite,
              Colors.red,
              0.7,
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              'Contrôles réguliers',
              'Faire un diagnostic tous les 3 mois',
              Icons.calendar_today,
              Colors.blue,
              0.5,
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              'Prévention',
              'Suivre les campagnes de sensibilisation',
              Icons.campaign,
              Colors.green,
              0.9,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(
    String title,
    String description,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildRecentDiagnostics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes Diagnostics Récents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigation vers liste complète
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentDiagnostics!.map((diagnostic) => _buildDiagnosticItem(diagnostic)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(Map<String, dynamic> diagnostic) {
    final statut = diagnostic['statut'] as String?;
    final statutColor = statut == 'positif' 
        ? Colors.red 
        : statut == 'negatif' 
            ? Colors.green 
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statutColor.withOpacity(0.2),
          child: Icon(
            statut == 'positif' ? Icons.warning : Icons.check_circle,
            color: statutColor,
          ),
        ),
        title: Text(
          diagnostic['maladie_type'] ?? 'Diagnostic',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut: ${statut ?? 'N/A'}'),
            Text('Date: ${diagnostic['created_at'] ?? 'N/A'}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            statut?.toUpperCase() ?? 'N/A',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: statutColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statutColor),
        ),
        onTap: () {
          // Navigation vers détail diagnostic
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions Rapides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Nouveau Diagnostic',
                    Icons.camera_alt,
                    Colors.blue,
                    () {
                      // Navigation vers création diagnostic
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Mes Rappels',
                    Icons.notifications,
                    Colors.orange,
                    () {
                      // Navigation vers rappels
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Historique',
                    Icons.history,
                    Colors.purple,
                    () {
                      // Navigation vers historique
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Partager',
                    Icons.share,
                    Colors.green,
                    () {
                      // Partage familial
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

