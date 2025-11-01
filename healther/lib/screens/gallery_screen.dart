import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/diagnostic.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

/// Écran Galerie de Photos avec Tags
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _apiService = ApiService();
  
  List<Diagnostic> _diagnostics = [];
  bool _isLoading = false;
  String? _selectedTag;
  String _viewMode = 'grid'; // 'grid' ou 'list'

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diagnostics = await _apiService.getDiagnostics(limit: 100);
      
      setState(() {
        _diagnostics = diagnostics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement diagnostics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> get _availableTags {
    final tags = <String>{};
    for (final diagnostic in _diagnostics) {
      if (diagnostic.region != null) tags.add('Région: ${diagnostic.region}');
      tags.add('Maladie: ${diagnostic.maladieType.name}');
      tags.add('Statut: ${diagnostic.statut.name}');
      if (diagnostic.createdAt != null) {
        final month = DateFormat('MMMM yyyy', 'fr').format(diagnostic.createdAt!);
        tags.add('Date: $month');
      }
    }
    return tags.toList()..sort();
  }

  List<Diagnostic> get _filteredDiagnostics {
    if (_selectedTag == null) return _diagnostics;
    
    return _diagnostics.where((diagnostic) {
      if (_selectedTag!.startsWith('Région: ')) {
        return diagnostic.region == _selectedTag!.replaceFirst('Région: ', '');
      }
      if (_selectedTag!.startsWith('Maladie: ')) {
        return diagnostic.maladieType.name ==
            _selectedTag!.replaceFirst('Maladie: ', '');
      }
      if (_selectedTag!.startsWith('Statut: ')) {
        return diagnostic.statut.name ==
            _selectedTag!.replaceFirst('Statut: ', '');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galerie de Photos'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
              });
            },
            tooltip: 'Changer vue',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres par tags
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTagChip(null, 'Tous'),
                      ..._availableTags.map((tag) => _buildTagChip(tag, tag)),
                    ],
                  ),
                ),
                const Divider(),
                // Grille ou liste de photos
                Expanded(
                  child: _viewMode == 'grid'
                      ? _buildGridView()
                      : _buildListView(),
                ),
              ],
            ),
    );
  }

  Widget _buildTagChip(String? tag, String label) {
    final isSelected = _selectedTag == tag;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedTag = selected ? tag : null;
          });
        },
      ),
    );
  }

  Widget _buildGridView() {
    final filtered = _filteredDiagnostics;

    if (filtered.isEmpty) {
      return const Center(child: Text('Aucune photo disponible'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final diagnostic = filtered[index];
        return _buildPhotoCard(diagnostic);
      },
    );
  }

  Widget _buildListView() {
    final filtered = _filteredDiagnostics;

    if (filtered.isEmpty) {
      return const Center(child: Text('Aucune photo disponible'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final diagnostic = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: diagnostic.imagePath != null
                ? Image.file(
                    File(diagnostic.imagePath!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : diagnostic.imageBase64 != null
                    ? Image.memory(
                        Uint8List.fromList(base64Decode(diagnostic.imageBase64!)),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 60),
            title: Text('${diagnostic.maladieType.name} - ${diagnostic.statut.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (diagnostic.region != null) Text('Région: ${diagnostic.region}'),
                if (diagnostic.createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(diagnostic.createdAt!),
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                _showImageDialog(diagnostic);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(Diagnostic diagnostic) {
    return GestureDetector(
      onTap: () => _showImageDialog(diagnostic),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            diagnostic.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(diagnostic.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : diagnostic.imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(base64Decode(diagnostic.imageBase64!)),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 40),
                      ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  diagnostic.maladieType.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(Diagnostic diagnostic) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('${diagnostic.maladieType.name} - ${diagnostic.statut.name}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: diagnostic.imagePath != null
                  ? Image.file(File(diagnostic.imagePath!), fit: BoxFit.contain)
                  : diagnostic.imageBase64 != null
                      ? Image.memory(
                          Uint8List.fromList(base64Decode(diagnostic.imageBase64!)),
                          fit: BoxFit.contain,
                        )
                      : const Center(child: Text('Image non disponible')),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (diagnostic.region != null)
                    Text('Région: ${diagnostic.region}'),
                  if (diagnostic.createdAt != null)
                    Text(
                      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(diagnostic.createdAt!)}',
                    ),
                  if (diagnostic.confiance != null)
                    Text('Confiance: ${(diagnostic.confiance! * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

