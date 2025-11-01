import 'map_heatmap_screen.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des statistiques: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapHeatmapScreen()),
              );
            },
            tooltip: 'Carte Heatmap',
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
                        _buildStatsCard(
                          'Statistiques Globales',
                          [
                            _StatItem(
                              'Total des cas',
                              _stats!['global']?['total']?.toString() ?? '0',
                              Icons.people,
                              Colors.blue,
                            ),
                            _StatItem(
                              'Cas positifs',
                              _stats!['global']?['positifs']?.toString() ?? '0',
                              Icons.warning,
                              Colors.red,
                            ),
                            _StatItem(
                              'Cas négatifs',
                              _stats!['global']?['negatifs']?.toString() ?? '0',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _StatItem(
                              'Taux de positivité',
                              '${_stats!['global']?['taux_positivite']?.toString() ?? '0'}%',
                              Icons.percent,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Par maladie
                        if (_stats!['par_maladie'] != null) ...[
                          _buildStatsCard(
                            'Paludisme',
                            [
                              _StatItem(
                                'Total',
                                _stats!['par_maladie']?['paludisme']?['total']?.toString() ?? '0',
                                Icons.bloodtype,
                                Colors.red,
                              ),
                              _StatItem(
                                'Positifs',
                                _stats!['par_maladie']?['paludisme']?['positifs']?.toString() ?? '0',
                                Icons.warning,
                                Colors.red,
                              ),
                              _StatItem(
                                'Taux',
                                '${_stats!['par_maladie']?['paludisme']?['taux_positivite']?.toString() ?? '0'}%',
                                Icons.trending_up,
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatsCard(
                            'Fièvre Typhoïde',
                            [
                              _StatItem(
                                'Total',
                                _stats!['par_maladie']?['typhoide']?['total']?.toString() ?? '0',
                                Icons.thermostat,
                                Colors.orange,
                              ),
                              _StatItem(
                                'Positifs',
                                _stats!['par_maladie']?['typhoide']?['positifs']?.toString() ?? '0',
                                Icons.warning,
                                Colors.orange,
                              ),
                              _StatItem(
                                'Taux',
                                '${_stats!['par_maladie']?['typhoide']?['taux_positivite']?.toString() ?? '0'}%',
                                Icons.trending_up,
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Par région
                        if (_stats!['par_region'] != null &&
                            (_stats!['par_region'] as List).isNotEmpty) ...[
                          Text(
                            'Par Région',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...(_stats!['par_region'] as List).map((region) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(region['region'] ?? 'Inconnu'),
                                subtitle: Text(
                                  'Total: ${region['total_cas']}, Positifs: ${region['cas_positifs']}, Négatifs: ${region['cas_negatifs']}',
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsCard(String title, List<_StatItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.color.withOpacity(0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(item.icon, color: item.color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

