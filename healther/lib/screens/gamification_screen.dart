import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

/// Écran de gamification avec badges et leaderboard
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _tabController = TabController(length: 2, vsync: this);

    final gamification = GamificationProvider();
    gamification.loadLeaderboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Mes Progrès'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer<GamificationProvider>(
      builder: (context, gamification, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de niveau actuel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: (gamification.userScore % 100) / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                'Niveau ${gamification.userLevel}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                gamification.userLevelName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Score',
                            '${gamification.userScore}',
                            Icons.stars,
                            Colors.amber,
                          ),
                          _buildStatItem(
                            'Diagnostics',
                            '${gamification.diagnosticsCount}',
                            Icons.medical_services,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Badges
              const Text(
                'Mes Badges',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (gamification.badges.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucun badge obtenu pour le moment. Continue !'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: gamification.badges.length,
                  itemBuilder: (context, index) {
                    final badge = gamification.badges[index];
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (sin(_animationController.value * 2 * pi) * 0.05),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    GamificationProvider.getBadgeIcon(badge),
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    GamificationProvider.getBadgeName(badge),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return Consumer<GamificationProvider>(
      builder: (context, gamification, _) {
        if (gamification.isLoadingLeaderboard) {
          return const Center(child: CircularProgressIndicator());
        }

        if (gamification.leaderboard.isEmpty) {
          return const Center(child: Text('Aucun classement disponible'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: gamification.leaderboard.length,
          itemBuilder: (context, index) {
            final entry = gamification.leaderboard[index];
            final rank = index + 1;
            final isTopThree = rank <= 3;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isTopThree ? 4 : 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(rank),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  entry['username'] ?? 'Inconnu',
                  style: TextStyle(
                    fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${entry['diagnostics'] ?? 0} diagnostics',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${entry['score'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.blue;
    }
  }
}

