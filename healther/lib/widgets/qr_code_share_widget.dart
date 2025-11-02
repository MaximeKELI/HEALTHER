import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
// Note: Pour QR code, nécessiterait qr_flutter package
// Si pas disponible, utiliser API externe ou service web

/// Widget pour partager via QR Code
class QRCodeShareWidget extends StatelessWidget {
  final String data;
  final String? title;
  final String? description;

  const QRCodeShareWidget({
    super.key,
    required this.data,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Partager'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (description != null) ...[
            Text(description!),
            const SizedBox(height: 16),
          ],
          // QR Code - nécessiterait qr_flutter
          // Pour l'instant, afficher un placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'QR Code\n(Nécessite qr_flutter)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanner ce code pour accéder aux données',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        TextButton(
          onPressed: () {
            Share.share(data);
          },
          child: const Text('Partager le lien'),
        ),
      ],
    );
  }
}

