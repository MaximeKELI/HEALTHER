import 'package:flutter/material.dart';

/// ListTile avec actions swipe
class SwipeableListTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeDelete;
  final VoidCallback? onSwipeEdit;
  final VoidCallback? onSwipeShare;
  final Color? backgroundColor;

  const SwipeableListTile({
    super.key,
    required this.child,
    this.onSwipeDelete,
    this.onSwipeEdit,
    this.onSwipeShare,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onSwipeShare != null)
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: onSwipeShare,
              ),
            if (onSwipeEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: onSwipeEdit,
              ),
            if (onSwipeDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: onSwipeDelete,
              ),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onSwipeDelete?.call();
        }
      },
      child: child,
    );
  }
}

