import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCardDetails();
  }

  Future<void> _loadSavedCardDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cardNumberController.text = prefs.getString('cardNumber') ?? '';
      _expiryDateController.text = prefs.getString('expiryDate') ?? '';
      _cvvController.text = prefs.getString('cvv') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wprowadź dane płatności'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cardNumberController,
            decoration: const InputDecoration(labelText: 'Numer karty'),
          ),
          TextField(
            controller: _expiryDateController,
            decoration: const InputDecoration(labelText: 'Data ważności (MM/RR)'),
          ),
          TextField(
            controller: _cvvController,
            decoration: const InputDecoration(labelText: 'CVV'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cardNumber', _cardNumberController.text);
            await prefs.setString('expiryDate', _expiryDateController.text);
            await prefs.setString('cvv', _cvvController.text);

            Navigator.pop(context, true);
          },
          child: const Text('Zapłać'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}