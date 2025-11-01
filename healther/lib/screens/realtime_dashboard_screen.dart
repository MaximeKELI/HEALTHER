import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/realtime_stats_service.dart';
import '../providers/gamification_provider.dart';

/// Dashboard temps réel avec graphiques animés
class RealtimeDashboardScreen extends StatefulWidget {
  const RealtimeDashboardScreen({super.key});

  @override
  State<RealtimeDashboardScreen> createState() => _RealtimeDashboardScreenState();
}

class _RealtimeDashboardScreenState extends State<RealtimeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Démarrer le service temps réel
    final realtimeService = RealtimeStatsService();
    final token = ApiService().getToken();
    if (token != null) {
      realtimeService.connectSocket(token);
      realtimeService.startPolling();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    RealtimeStatsService().disconnectSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Temps Réel'),
        actions: [
          Consumer<RealtimeStatsService>(
            builder: (context, service, _) {
              return Container(
                margin: const EdgeInsets.all(8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: service.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<RealtimeStatsService>(
          builder: (context, realtimeService, _) {
            final stats = realtimeService.stats;
            final timeSeries = realtimeService.timeSeries;

            if (stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                await realtimeService.fetchStats();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicateur temps réel
                    _buildRealtimeIndicator(realtimeService.isConnected),
                    const SizedBox(height: 16),

                    // Graphique temporel animé
                    if (timeSeries.isNotEmpty) ...[
                      _buildTimeSeriesChart(timeSeries),
                      const SizedBox(height: 16),
                    ],

                    // Statistiques globales avec animations
                    _buildAnimatedStatsCard(
                      'Statistiques Globales',
                      stats['global'],
                    ),
                    const SizedBox(height: 16),

                    // Graphique circulaire (pie chart) pour répartition
                    _buildPieChart(stats['global']),
                    const SizedBox(height: 16),

                    // Par maladie avec graphiques
                    if (stats['par_maladie'] != null) ...[
                      _buildMaladieChart(stats['par_maladie']),
                      const SizedBox(height: 16),
                    ],

                    // Gamification widget
                    Consumer<GamificationProvider>(
                      builder: (context, gamification, _) {
                        return _buildGamificationCard(gamification);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRealtimeIndicator(bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Données en temps réel' : 'Mode hors ligne',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSeriesChart(List<Map<String, dynamic>> timeSeries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution Temporelle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: timeSeries.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['positifs'] as num?)?.toDouble() ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatsCard(String title, Map<String, dynamic>? global) {
    if (global == null) return const SizedBox.shrink();

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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _buildAnimatedStatItem(
                  'Total',
                  (global['total'] ?? 0).toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildAnimatedStatItem(
                  'Positifs',
                  (global['positifs'] ?? 0).toString(),
                  Icons.warning,
                  Colors.red,
                ),
                _buildAnimatedStatItem(
                  'Négatifs',
                  (global['negatifs'] ?? 0).toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildAnimatedStatItem(
                  'Taux',
                  '${(global['taux_positivite'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(Map<String, dynamic>? global) {
    if (global == null) return const SizedBox.shrink();

    final positifs = (global['positifs'] ?? 0) as int;
    final negatifs = (global['negatifs'] ?? 0) as int;
    final total = positifs + negatifs;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des Cas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: positifs.toDouble(),
                      title: '${(positifs / total * 100).toStringAsFixed(1)}%',
                      color: Colors.red,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: negatifs.toDouble(),
                      title: '${(negatifs / total * 100).toStringAsFixed(1)}%',
                      color: Colors.green,
                      radius: 80,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaladieChart(Map<String, dynamic> maladies) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Par Maladie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() == 0) return const Text('Paludisme');
                          if (value.toInt() == 1) return const Text('Typhoïde');
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: (maladies['paludisme']?['taux_positivite'] ?? 0.0).toDouble(),
                          color: Colors.red,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: (maladies['typhoide']?['taux_positivite'] ?? 0.0).toDouble(),
                          color: Colors.orange,
                          width: 40,
                        ),
                      ],
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

  Widget _buildGamificationCard(GamificationProvider gamification) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Progrès',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: ${gamification.userScore}'),
                      Text('Niveau: ${gamification.userLevel} (${gamification.userLevelName})'),
                      Text('Diagnostics: ${gamification.diagnosticsCount}'),
                    ],
                  ),
                ),
                if (gamification.badges.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: gamification.badges.map((badge) {
                      return Tooltip(
                        message: GamificationProvider.getBadgeName(badge),
                        child: Text(
                          GamificationProvider.getBadgeIcon(badge),
                          style: const TextStyle(fontSize: 24),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

