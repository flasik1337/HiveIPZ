import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayDialog extends StatelessWidget {
  final String eventId;

  const QrDisplayDialog({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final qrData = "https://vps.jakosinski.pl/events/$eventId/checkin";



    return AlertDialog(
      title: const Text("Kod QR do zeskanowania"),
      content: SizedBox(
        width: 200,
        height: 200,
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Zamknij"),
        ),
      ],
    );
  }
}
