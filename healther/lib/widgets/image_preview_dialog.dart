import 'dart:io';
import 'package:flutter/material.dart';

/// Dialog pour preview et éditer une image avant upload
class ImagePreviewDialog extends StatefulWidget {
  final File imageFile;
  final Function(File editedFile)? onSave;

  const ImagePreviewDialog({
    super.key,
    required this.imageFile,
    this.onSave,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  File? _editedImage;
  double _rotation = 0;
  bool _isMirrored = false;

  @override
  void initState() {
    super.initState();
    _editedImage = widget.imageFile;
  }

  void _rotateImage() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  void _mirrorImage() {
    setState(() {
      _isMirrored = !_isMirrored;
    });
  }

  Future<void> _applyTransformations() async {
    // Note: L'édition d'image complète nécessiterait un package comme image_editor
    // Pour l'instant, on retourne juste l'image originale
    widget.onSave?.call(widget.imageFile);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            AppBar(
              title: const Text('Aperçu de l\'image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            // Image preview
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Transform.rotate(
                    angle: _rotation * 3.14159 / 180,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(_isMirrored ? 3.14159 : 0),
                      child: Image.file(
                        _editedImage ?? widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.rotate_right),
                    onPressed: _rotateImage,
                    tooltip: 'Tourner',
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip),
                    onPressed: _mirrorImage,
                    tooltip: 'Miroir',
                  ),
                  ElevatedButton.icon(
                    onPressed: _applyTransformations,
                    icon: const Icon(Icons.check),
                    label: const Text('Utiliser cette image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

