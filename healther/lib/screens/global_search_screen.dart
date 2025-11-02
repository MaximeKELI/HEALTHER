import 'history_screen.dart';
import 'diagnostic_screen.dart';
import '../models/diagnostic.dart';
import 'package:flutter/material.dart';
import '../widgets/global_search_bar.dart';
import '../services/global_search_service.dart';
import '../services/haptic_feedback_service.dart';

/// Écran de recherche globale
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final GlobalSearchService _searchService = GlobalSearchService();
  final HapticFeedbackService _haptic = HapticFeedbackService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic> _results = {};
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = {};
        _isSearching = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    _haptic.selectionClick();

    final results = await _searchService.globalSearch(query: query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche Globale'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlobalSearchBar(
              hintText: 'Rechercher diagnostics, patients...',
              onSearch: _performSearch,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_results['total'] == 0) {
      return _buildNoResults();
    }

    return _buildResults();
  }

  Widget _buildEmptyState() {
    final history = _searchService.getSearchHistory();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recherches récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune recherche récente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...history.map((term) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchService.clearHistory();
                  setState(() {});
                },
              ),
              onTap: () {
                _searchController.text = term;
                _performSearch(term);
              },
            )),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat pour "$_currentQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final diagnostics = _results['diagnostics'] as List<Diagnostic>? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (diagnostics.isNotEmpty) ...[
          const Text(
            'Diagnostics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...diagnostics.map((diagnostic) => Card(
            child: ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text('${diagnostic.maladieType} - ${diagnostic.statut}'),
              subtitle: Text(
                diagnostic.createdAt != null
                    ? '${diagnostic.createdAt!.day}/${diagnostic.createdAt!.month}/${diagnostic.createdAt!.year}'
                    : 'Date inconnue',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(),
                  ),
                );
              },
            ),
          )),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

