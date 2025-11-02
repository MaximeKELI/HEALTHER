import 'package:flutter/material.dart';

/// Widget pour basculer entre vue liste et grille
class ViewToggleWidget extends StatelessWidget {
  final bool isListView;
  final Function(bool) onToggle;

  const ViewToggleWidget({
    super.key,
    required this.isListView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [isListView, !isListView],
      onPressed: (index) {
        onToggle(index == 0);
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(
        minHeight: 36,
        minWidth: 36,
      ),
      children: const [
        Icon(Icons.list, size: 20),
        Icon(Icons.grid_view, size: 20),
      ],
    );
  }
}

