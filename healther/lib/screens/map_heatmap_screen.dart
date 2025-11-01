import 'package:flutter/material.dart';
import '../services/geofencing_service.dart';

class MapHeatmapScreen extends StatefulWidget {
  const MapHeatmapScreen({super.key});

  @override
  State<MapHeatmapScreen> createState() => _MapHeatmapScreenState();
}

class _MapHeatmapScreenState extends State<MapHeatmapScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  List<Map<String, dynamic>> _heatmapData = [];
  Map<String, dynamic>? _alerts;
  bool _isLoading = false;
  String? _selectedRegion;
  String? _selectedMaladieType;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
    _checkAlerts();
  }

  Future<void> _loadHeatmap() async {
    setState(() => _isLoading = true);

    try {
      _heatmapData = await _geofencingService.getHeatmap(
        region: _selectedRegion,
        maladieType: _selectedMaladieType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement heatmap: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAlerts() async {
    try {
      _alerts = await _geofencingService.checkAlerts(
        region: _selectedRegion,
      );
    } catch (e) {
      print('Erreur vérification alertes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte - Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadHeatmap();
              _checkAlerts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      hint: const Text('Région'),
                      isExpanded: true,
                      items: ['Lomé', 'Kara', 'Sokodé', 'Atakpamé'].map((region) {
                        return DropdownMenuItem(value: region, child: Text(region));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value;
                        });
                        _loadHeatmap();
                        _checkAlerts();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMaladieType,
                      hint: const Text('Maladie'),
                      isExpanded: true,
                      items: ['paludisme', 'typhoide', 'mixte'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMaladieType = value;
                        });
                        _loadHeatmap();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Alertes
          if (_alerts != null && (_alerts!['alerts'] as List).isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_alerts!['count']} alerte(s) détectée(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Carte/Heatmap (placeholder - ici vous intégreriez une vraie carte)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _heatmapData.isEmpty
                    ? const Center(child: Text('Aucune donnée disponible'))
                    : ListView.builder(
                        itemCount: _heatmapData.length,
                        itemBuilder: (context, index) {
                          final point = _heatmapData[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorForCaseCount(
                                  point['case_count'] as int? ?? 0,
                                ),
                                child: Text(
                                  '${point['case_count'] ?? 0}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${point['region'] ?? 'N/A'} - ${point['prefecture'] ?? 'N/A'}',
                              ),
                              subtitle: Text(
                                'Positifs: ${point['positive_count'] ?? 0}',
                              ),
                              trailing: Text(
                                'Lat: ${point['latitude']?.toStringAsFixed(4) ?? 'N/A'}\n'
                                'Lng: ${point['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCaseCount(int count) {
    if (count >= 50) return Colors.red;
    if (count >= 20) return Colors.orange;
    if (count >= 10) return Colors.yellow;
    return Colors.green;
  }
}

