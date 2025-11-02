import 'package:intl/intl.dart';
import 'ml_feedback_screen.dart';
import '../models/diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/swipeable_list_tile.dart';
import '../providers/diagnostic_provider.dart';
import '../services/haptic_feedback_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HapticFeedbackService _haptic = HapticFeedbackService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiagnostics();
    });
  }

  void _loadDiagnostics() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final diagnosticProvider = Provider.of<DiagnosticProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      diagnosticProvider.loadDiagnostics(userId: user.id);
    }
  }

  Color _getStatusColor(StatutDiagnostic statut) {
    switch (statut) {
      case StatutDiagnostic.positif:
        return Colors.red;
      case StatutDiagnostic.negatif:
        return Colors.green;
      case StatutDiagnostic.incertain:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(StatutDiagnostic statut) {
    switch (statut) {
      case StatutDiagnostic.positif:
        return Icons.warning;
      case StatutDiagnostic.negatif:
        return Icons.check_circle;
      case StatutDiagnostic.incertain:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnosticProvider = Provider.of<DiagnosticProvider>(context);

    return Scaffold(
      body: diagnosticProvider.isLoading && diagnosticProvider.diagnostics.isEmpty
          ? const DiagnosticListSkeleton(itemCount: 5)
          : diagnosticProvider.diagnostics.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.history,
                  title: 'Aucun diagnostic',
                  message: 'Vous n\'avez pas encore créé de diagnostic.\nCommencez par créer votre premier diagnostic !',
                  actionLabel: 'Nouveau Diagnostic',
                  onAction: () {
                    // Navigation vers diagnostic screen
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _haptic.lightImpact();
                    _loadDiagnostics();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: diagnosticProvider.diagnostics.length,
                    itemBuilder: (context, index) {
                      final diagnostic = diagnosticProvider.diagnostics[index];
                      final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

                      return SwipeableListTile(
                        onSwipeDelete: () {
                          _haptic.mediumImpact();
                          // TODO: Implémenter suppression
                        },
                        onSwipeShare: () {
                          _haptic.selectionClick();
                          // TODO: Implémenter partage
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getStatusColor(diagnostic.statut).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(diagnostic.statut),
                                color: _getStatusColor(diagnostic.statut),
                              ),
                            ),
                            title: Text(diagnostic.maladieTypeLabel),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statut: ${diagnostic.statutLabel}',
                                  style: TextStyle(
                                    color: _getStatusColor(diagnostic.statut),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (diagnostic.region != null)
                                  Text('Région: ${diagnostic.region}'),
                                if (diagnostic.createdAt != null)
                                  Text(
                                    dateFormat.format(diagnostic.createdAt!),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: diagnostic.confiance != null
                                ? Chip(
                                    label: Text(
                                      '${diagnostic.confiance!.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(diagnostic.statut).withOpacity(0.1),
                                  )
                                : null,
                            onTap: () {
                              _haptic.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MLFeedbackScreen(
                                    diagnostic: diagnostic,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}



