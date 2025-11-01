import 'package:intl/intl.dart';
import '../models/diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/diagnostic_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
      body: diagnosticProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : diagnosticProvider.diagnostics.isEmpty
              ? const Center(
                  child: Text('Aucun diagnostic enregistré'),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadDiagnostics();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: diagnosticProvider.diagnostics.length,
                    itemBuilder: (context, index) {
                      final diagnostic = diagnosticProvider.diagnostics[index];
                      final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

                      return Card(
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
                            // TODO: Naviguer vers les détails du diagnostic
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


