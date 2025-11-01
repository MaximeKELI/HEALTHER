import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:animations/animations.dart';
import '../services/geofencing_service.dart';
import 'package:flutter_map/flutter_map.dart';

/// Carte interactive avec propagation animée des épidémies
class AnimatedMapScreen extends StatefulWidget {
  const AnimatedMapScreen({super.key});

  @override
  State<AnimatedMapScreen> createState() => _AnimatedMapScreenState();
}

class _AnimatedMapScreenState extends State<AnimatedMapScreen>
    with SingleTickerProviderStateMixin {
  final GeofencingService _geofencingService = GeofencingService();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _heatmapData = [];
  Map<String, dynamic>? _alerts;
  bool _isLoading = false;
  String? _selectedRegion;
  String? _selectedMaladieType;
  bool _isPlayingAnimation = false;
  Timer? _animationTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Timeline pour animation de propagation
  int _currentTimeIndex = 0;
  List<List<Map<String, dynamic>>> _timeSeriesData = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadHeatmap();
    _checkAlerts();

    // Générer des données temporelles simulées pour l'animation
    _generateTimeSeriesData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _animationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _generateTimeSeriesData() {
    // Simuler des données sur 10 timesteps
    for (int i = 0; i < 10; i++) {
      final data = _heatmapData.map((point) {
        final multiplier = 1.0 + (i * 0.1); // Augmentation progressive
        return {
          ...point,
          'case_count': ((point['case_count'] ?? 0) * multiplier).round(),
          'positive_count': ((point['positive_count'] ?? 0) * multiplier).round(),
        };
      }).toList();
      _timeSeriesData.add(data);
    }
  }

  Future<void> _loadHeatmap() async {
    setState(() => _isLoading = true);

    try {
      _heatmapData = await _geofencingService.getHeatmap(
        region: _selectedRegion,
        maladieType: _selectedMaladieType,
      );
      _generateTimeSeriesData();
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

  void _startPropagationAnimation() {
    if (_isPlayingAnimation) {
      _stopPropagationAnimation();
      return;
    }

    _isPlayingAnimation = true;
    _currentTimeIndex = 0;

    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentTimeIndex = (_currentTimeIndex + 1) % _timeSeriesData.length;
      });
    });
  }

  void _stopPropagationAnimation() {
    _isPlayingAnimation = false;
    _animationTimer?.cancel();
    _currentTimeIndex = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _isPlayingAnimation
        ? (_timeSeriesData.isNotEmpty ? _timeSeriesData[_currentTimeIndex] : _heatmapData)
        : _heatmapData;

    // Centrer sur le Togo (par défaut)
    final center = LatLng(8.6195, 0.8268);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte - Propagation Animée'),
        actions: [
          IconButton(
            icon: Icon(_isPlayingAnimation ? Icons.stop : Icons.play_arrow),
            onPressed: _startPropagationAnimation,
            tooltip: _isPlayingAnimation ? 'Arrêter animation' : 'Démarrer animation',
          ),
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
          // Filtres et contrôles
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
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
                  // Timeline slider pour animation
                  if (_isPlayingAnimation) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Temps: '),
                        Expanded(
                          child: Slider(
                            value: _currentTimeIndex.toDouble(),
                            min: 0,
                            max: (_timeSeriesData.length - 1).toDouble(),
                            divisions: _timeSeriesData.length - 1,
                            onChanged: (value) {
                              setState(() {
                                _currentTimeIndex = value.round();
                              });
                            },
                          ),
                        ),
                        Text('${_currentTimeIndex + 1}/${_timeSeriesData.length}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Alertes
          if (_alerts != null && (_alerts!['alerts'] as List).isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
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

          // Carte interactive
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentData.isEmpty
                    ? const Center(child: Text('Aucune donnée disponible'))
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 7.0,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.healther.app',
                          ),
                          // Marqueurs animés pour les cas
                          MarkerLayer(
                            markers: currentData.map((point) {
                              final lat = point['latitude'] as double?;
                              final lng = point['longitude'] as double?;
                              final caseCount = point['case_count'] as int? ?? 0;
                              final positiveCount = point['positive_count'] as int? ?? 0;

                              if (lat == null || lng == null) return null;

                              return Marker(
                                point: LatLng(lat, lng),
                                width: 80,
                                height: 80,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return FadeScaleTransition(
                                      animation: AlwaysStoppedAnimation(_pulseAnimation.value),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _getColorForCaseCount(caseCount)
                                              .withOpacity(0.7 * _pulseAnimation.value),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _getColorForCaseCount(caseCount),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$caseCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (positiveCount > 0)
                                                Text(
                                                  '$positiveCount+',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).whereType<Marker>().toList(),
                          ),
                          // Zones d'alerte
                          if (_alerts != null && (_alerts!['alerts'] as List).isNotEmpty)
                            CircleLayer(
                              circles: (_alerts!['alerts'] as List).map((alert) {
                                final location = alert['location'];
                                final lat = location?['latitude'] as double?;
                                final lng = location?['longitude'] as double?;
                                final radius = location?['radius'] as double? ?? 1000;

                                if (lat == null || lng == null) return null;

                                return CircleMarker(
                                  point: LatLng(lat, lng),
                                  radius: radius,
                                  color: Colors.red.withOpacity(0.2),
                                  borderColor: Colors.red,
                                  borderStrokeWidth: 2,
                                );
                              }).whereType<CircleMarker>().toList(),
                            ),
                        ],
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

