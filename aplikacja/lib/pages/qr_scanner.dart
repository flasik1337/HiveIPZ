import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/database_helper.dart';
import '../styles/hive_colors.dart';


class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  Future<void> _handleBarcode(String rawCode, BuildContext context) async {
    final code = rawCode.trim();
    print("Zeskanowany kod QR: $code");

    // 1. Obsługa: ticket:<numer>
    if (code.startsWith('ticket:')) {
      final ticketNumber = code.split(':')[1].trim();
      if (ticketNumber.isNotEmpty) {
        _showTicketDialog(ticketNumber, context);
        return;
      }
    }

    // 2. Obsługa pełnego URL z /ticket/<numer>
    if (code.contains('/ticket/')) {
      final regex = RegExp(r'/ticket/([^/?#]+)');
      final match = regex.firstMatch(code);
      if (match != null) {
        final ticketNumber = match.group(1);
        if (ticketNumber != null && ticketNumber.isNotEmpty) {
          _showTicketDialog(ticketNumber, context);
          return;
        }
      }
    }

    // 3. Obsługa samego numeru (np. "TKT123456")
    if (RegExp(r'^[A-Za-z0-9\-_]{6,}$').hasMatch(code)) {
      _showTicketDialog(code, context);
      return;
    }

    // 4. Obsługa event_id
    String? eventId;
    if (code.contains('event_id=')) {
      eventId = Uri.parse(code).queryParameters['event_id'];
    } else if (RegExp(r'^\d+$').hasMatch(code)) {
      eventId = code;
    }

    if (eventId != null) {
      final token = await DatabaseHelper.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nie jesteś zalogowany")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse("https://vps.jakosinski.pl/events/$eventId/checkin"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${result['message']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['error'] ?? 'Błąd'}")),
        );
      }

      Navigator.pop(context);
      return;
    }

    // 5. Jeśli nic nie pasuje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nieprawidłowy kod QR")),
    );
  }


  Future<void> _showTicketDialog(String ticketNumber, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse("https://vps.jakosinski.pl:5000/ticket/$ticketNumber"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("🎫 Szczegóły biletu"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Imię i nazwisko: ${data['user_name']} ${data['user_surname']}"),
                Text("Nick: ${data['nickName']}"),
                Text("Wydarzenie: ${data['event_name']}"),
                Text("Miejsce: ${data['event_location']}"),
                Text("Data: ${data['event_date']}"),
                Text("Numer biletu: ${data['ticket_number']}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Zamknij"),
              ),
            ],
          ),
        );
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Błąd pobierania biletu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $errorMsg")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd sieci: $e")),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Skanuj kod QR",
          style: TextStyle(color: HiveColors.main), // 🟡 Twój żółty kolor
        ),
        iconTheme: const IconThemeData(color: HiveColors.main), // 🟡 Ikona wstecz
        backgroundColor: Colors.black, // lub HiveColors.background jeśli masz
        centerTitle: true,
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (capture) {
          for (final barcode in capture.barcodes) {
            final code = barcode.rawValue;
            if (code != null) {
              _handleBarcode(code, context);
              break;
            }
          }
        },
      ),
    );
  }
}
