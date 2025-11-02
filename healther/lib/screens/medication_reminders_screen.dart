import 'package:flutter/material.dart';
import '../services/medication_service.dart';
import '../services/multi_channel_notification_service.dart';

/// Écran de Gestion des Rappels de Médication
class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() => _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  final MedicationService _medicationService = MedicationService();
  final MultiChannelNotificationService _notificationService =
      MultiChannelNotificationService();
  
  List<dynamic>? _reminders;
  Map<String, dynamic>? _adherenceStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadAdherenceStats();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _medicationService.getReminders();
      setState(() {
        _reminders = result['reminders'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement rappels: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAdherenceStats() async {
    try {
      final stats = await _medicationService.getAdherenceStatistics();
      setState(() {
        _adherenceStats = stats['statistics'];
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  Future<void> _markTaken(int reminderId) async {
    try {
      await _medicationService.markTaken(reminderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médicament marqué comme pris'),
          backgroundColor: Colors.green,
        ),
      );
      _loadReminders();
      _loadAdherenceStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addReminder() async {
    // Navigation vers formulaire de création
    // TODO: Créer écran de création de rappel
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rappels de Médication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addReminder,
            tooltip: 'Ajouter un rappel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadReminders();
              _loadAdherenceStats();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadReminders();
                await _loadAdherenceStats();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques d'observance
                    if (_adherenceStats != null) _buildAdherenceStats(),

                    const SizedBox(height: 20),

                    // Liste des rappels
                    const Text(
                      'Mes Rappels Actifs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_reminders == null || _reminders!.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('Aucun rappel actif'),
                          ),
                        ),
                      )
                    else
                      ..._reminders!.map((reminder) => _buildReminderCard(reminder)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdherenceStats() {
    final adherenceRate = _adherenceStats!['adherence_rate'] ?? 0.0;
    final totalReminders = _adherenceStats!['total_reminders'] ?? 0;
    final totalTaken = _adherenceStats!['total_taken'] ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Taux', '${adherenceRate.toStringAsFixed(1)}%', Colors.blue),
                _buildStatItem('Rappels', totalReminders.toString(), Colors.orange),
                _buildStatItem('Pris', totalTaken.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: adherenceRate / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                adherenceRate >= 80 ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final medicationName = reminder['medication_name'] ?? 'N/A';
    final dosage = reminder['dosage'] ?? '';
    final frequency = reminder['frequency'] ?? 'daily';
    final timesPerDay = reminder['times_per_day'] ?? 1;
    final startDate = reminder['start_date'] ?? '';
    final endDate = reminder['end_date'];
    final interactionWarnings = reminder['interaction_warnings'];

    final hasInteractions = interactionWarnings != null && interactionWarnings.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dosage.isNotEmpty)
                        Text(
                          'Dosage: $dosage',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasInteractions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Interactions',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '$timesPerDay fois/jour - ${_formatFrequency(frequency)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (startDate.isNotEmpty || endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Du $startDate${endDate != null ? ' au $endDate' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _markTaken(reminder['id']),
              icon: const Icon(Icons.check_circle),
              label: const Text('Marquer comme pris'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'as_needed':
        return 'Si nécessaire';
      default:
        return frequency;
    }
  }
}

