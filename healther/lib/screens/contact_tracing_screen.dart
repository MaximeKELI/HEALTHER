import 'package:flutter/material.dart';
import '../services/contact_tracing_service.dart';
import '../services/api_service.dart';

/// Écran Contact Tracing / Investigation d'Épidémie
class ContactTracingScreen extends StatefulWidget {
  final int? diagnosticId;
  final int? patientId;

  const ContactTracingScreen({
    super.key,
    this.diagnosticId,
    this.patientId,
  });

  @override
  State<ContactTracingScreen> createState() => _ContactTracingScreenState();
}

class _ContactTracingScreenState extends State<ContactTracingScreen> {
  final ContactTracingService _contactTracingService = ContactTracingService();
  
  Map<String, dynamic>? _investigationReport;
  Map<String, dynamic>? _r0Stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.diagnosticId != null) {
        final report = await _contactTracingService.generateInvestigationReport(
          widget.diagnosticId!,
        );
        setState(() {
          _investigationReport = report;
        });
      }

      if (widget.patientId != null) {
        final graph = await _contactTracingService.getTransmissionGraph(
          widget.patientId!,
        );
        setState(() {
          _investigationReport = graph;
        });
      }

      final r0Stats = await _contactTracingService.calculateR0();
      setState(() {
        _r0Stats = r0Stats;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement données: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Tracing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques R0
                    if (_r0Stats != null) _buildR0Card(),

                    const SizedBox(height: 20),

                    // Rapport d'investigation
                    if (_investigationReport != null)
                      _buildInvestigationReport(),

                    const SizedBox(height: 20),

                    // Contacts
                    if (_investigationReport != null &&
                        _investigationReport!['report'] != null &&
                        _investigationReport!['report']['contacts'] != null)
                      _buildContactsCard(
                        _investigationReport!['report']['contacts'],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildR0Card() {
    final r0 = _r0Stats!['R0'] ?? 0.0;
    final totalInfected = _r0Stats!['totalInfected'] ?? 0;
    final totalContacts = _r0Stats!['totalContacts'] ?? 0;
    final transmissionRate = _r0Stats!['transmissionRate'] ?? 0.0;

    Color r0Color = r0 < 1 ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taux de Reproduction (R0)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('R0', r0.toStringAsFixed(2), r0Color),
                _buildStatItem('Infectés', totalInfected.toString(), Colors.orange),
                _buildStatItem('Contacts', totalContacts.toString(), Colors.blue),
                _buildStatItem(
                  'Taux Transmission',
                  '${(transmissionRate * 100).toStringAsFixed(1)}%',
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (r0 > 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ R0 > 1 : L\'épidémie est en expansion',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
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
                        '✅ R0 < 1 : L\'épidémie est sous contrôle',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildInvestigationReport() {
    final report = _investigationReport!['report'];
    if (report == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapport d\'Investigation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (report['diagnostic'] != null)
              _buildDiagnosticInfo(report['diagnostic']),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfo(Map<String, dynamic> diagnostic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Maladie', diagnostic['maladie_type'] ?? 'N/A'),
        _buildInfoRow('Statut', diagnostic['statut'] ?? 'N/A'),
        _buildInfoRow('Date', diagnostic['date'] ?? 'N/A'),
        _buildInfoRow('Région', diagnostic['region'] ?? 'N/A'),
        if (diagnostic['location'] != null)
          _buildInfoRow(
            'Localisation',
            '${diagnostic['location']['latitude']}, ${diagnostic['location']['longitude']}',
          ),
      ],
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

  Widget _buildContactsCard(Map<String, dynamic> contacts) {
    final contactList = contacts['list'] as List<dynamic>? ?? [];
    final totalContacts = contacts['total'] ?? 0;

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
                  'Contacts Identifiés',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('$totalContacts contacts'),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (contactList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Aucun contact identifié'),
                ),
              )
            else
              ...contactList.take(10).map((contact) => _buildContactItem(contact)),
            if (contactList.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '... et ${contactList.length - 10} autres contacts',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text(contact['username'] ?? 'Contact inconnu'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${contact['distance_meters'] ?? 0}m'),
            Text('Date: ${contact['date'] ?? 'N/A'}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            // Navigation vers détail contact
          },
        ),
      ),
    );
  }
}

