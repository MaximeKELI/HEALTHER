import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

/// Écran pour les alertes proactives basées sur seuils
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _alertsData;
  Map<String, dynamic>? _alertHistory;
  bool _isLoading = false;
  String? _selectedRegion;
  String? _selectedMaladie;

  @override
  void initState() {
    super.initState();
    _checkAlerts();
    _loadHistory();
  }

  Future<void> _checkAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await _apiService.checkAlerts(
        region: _selectedRegion,
        maladieType: _selectedMaladie,
        days: 7,
      );
      
      setState(() {
        _alertsData = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur vérification alertes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getAlertHistory(limit: 20);
      setState(() {
        _alertHistory = history;
      });
    } catch (e) {
      print('Erreur chargement historique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes Proactives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAlerts();
              _loadHistory();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _checkAlerts();
                await _loadHistory();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtres
                    _buildFilters(),
                    
                    const SizedBox(height: 20),
                    
                    // Alertes actuelles
                    if (_alertsData != null) _buildCurrentAlerts(),
                    
                    const SizedBox(height: 20),
                    
                    // Historique
                    if (_alertHistory != null) _buildHistory(),
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
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _checkAlerts();
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
                      _checkAlerts();
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

  Widget _buildCurrentAlerts() {
    final alerts = _alertsData!['alerts'] as List<dynamic>? ?? [];
    final hasAlerts = _alertsData!['hasAlerts'] as bool? ?? false;

    if (!hasAlerts || alerts.isEmpty) {
      return Card(
        elevation: 4,
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Aucune alerte active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertes Actives (${alerts.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...alerts.map((alert) {
          final a = alert as Map<String, dynamic>;
          final type = a['type'] as String? ?? 'warning';
          final color = type == 'critical' ? Colors.red : Colors.orange;
          final icon = type == 'critical' ? Icons.error : Icons.warning;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 10),
            color: color.withOpacity(0.1),
            child: ListTile(
              leading: Icon(icon, color: color, size: 30),
              title: Text(
                a['message'] as String? ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Région: ${a['region'] ?? 'Toutes'}'),
                  Text(
                    'Valeur actuelle: ${a['currentValue']} (Seuil: ${a['threshold']})',
                  ),
                  if (a['date'] != null)
                    Text(
                      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(a['date']))}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: Chip(
                label: Text(type.toUpperCase()),
                backgroundColor: color.withOpacity(0.2),
                labelStyle: TextStyle(color: color, fontSize: 10),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistory() {
    final alerts = _alertHistory!['alerts'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des Alertes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (alerts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucun historique disponible'),
            ),
          )
        else
          ...alerts.map((alert) {
            final a = alert as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  a['type'] == 'critical' ? Icons.error : Icons.warning,
                  color: a['type'] == 'critical' ? Colors.red : Colors.orange,
                ),
                title: Text(a['message'] ?? ''),
                subtitle: Text(a['date'] ?? ''),
                trailing: Chip(
                  label: Text((a['type'] ?? 'warning').toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
              ),
            );
          }),
      ],
    );
  }
}

