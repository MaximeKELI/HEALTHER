import 'package:flutter/material.dart';
import '../services/haptic_feedback_service.dart';

/// Menu FAB avec actions rapides
class QuickActionsFAB extends StatefulWidget {
  final Function()? onNewDiagnostic;
  final Function()? onScanPrescription;
  final Function()? onScanBarcode;
  final Function()? onVoiceCommand;

  const QuickActionsFAB({
    super.key,
    this.onNewDiagnostic,
    this.onScanPrescription,
    this.onScanBarcode,
    this.onVoiceCommand,
  });

  @override
  State<QuickActionsFAB> createState() => _QuickActionsFABState();
}

class _QuickActionsFABState extends State<QuickActionsFAB>
    with SingleTickerProviderStateMixin {
  final HapticFeedbackService _haptic = HapticFeedbackService();
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _haptic.mediumImpact();
      } else {
        _animationController.reverse();
        _haptic.selectionClick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Actions expandues
        if (_isExpanded) ...[
          _buildActionButton(
            icon: Icons.mic,
            label: 'Assistant Vocal',
            onTap: () {
              widget.onVoiceCommand?.call();
              _toggleMenu();
            },
            offset: 4,
          ),
          _buildActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scanner Code',
            onTap: () {
              widget.onScanBarcode?.call();
              _toggleMenu();
            },
            offset: 3,
          ),
          _buildActionButton(
            icon: Icons.description,
            label: 'Scan Prescription',
            onTap: () {
              widget.onScanPrescription?.call();
              _toggleMenu();
            },
            offset: 2,
          ),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Nouveau Diagnostic',
            onTap: () {
              widget.onNewDiagnostic?.call();
              _toggleMenu();
            },
            offset: 1,
          ),
        ],
        // FAB Principal
        FloatingActionButton(
          onPressed: _toggleMenu,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int offset,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          offset * 0.1,
          0.5 + offset * 0.1,
          curve: Curves.easeOut,
        ),
      )),
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: EdgeInsets.only(bottom: 80.0 + (offset * 60.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'action_$offset',
                onPressed: onTap,
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

