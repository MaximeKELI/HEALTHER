import 'dart:async';
import 'package:flutter/material.dart';
import '../services/global_search_service.dart';
import '../services/haptic_feedback_service.dart';

/// Barre de recherche globale
class GlobalSearchBar extends StatefulWidget {
  final Function(String query)? onSearch;
  final Function()? onOpen;
  final Function()? onClose;
  final String? hintText;

  const GlobalSearchBar({
    super.key,
    this.onSearch,
    this.onOpen,
    this.onClose,
    this.hintText,
  });

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final GlobalSearchService _searchService = GlobalSearchService();
  final HapticFeedbackService _haptic = HapticFeedbackService();
  Timer? _debounceTimer;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions(String query) async {
    final suggestions = await _searchService.getSuggestions(query);
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = query.isNotEmpty || suggestions.isNotEmpty;
      });
    }
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadSuggestions(query);
      if (query.isNotEmpty) {
        widget.onSearch?.call(query);
      }
    });
  }

  void _onSearch(String query) {
    _haptic.selectionClick();
    widget.onSearch?.call(query);
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: false,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Rechercher diagnostics, patients... (Ctrl+K)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            setState(() {});
            _onQueryChanged(value);
          },
          onSubmitted: _onSearch,
          onTap: () {
            widget.onOpen?.call();
            _haptic.selectionClick();
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(suggestion),
                    onTap: () {
                      _controller.text = suggestion;
                      _onSearch(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

