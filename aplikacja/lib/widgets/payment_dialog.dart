import 'package:Hive/styles/hive_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  String? _cardNumberError;

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

  bool _validateCardNumber() {
    final cardNumber = _cardNumberController.text;
    if (cardNumber.length != 16) {
      setState(() {
        _cardNumberError = 'Niepoprawny numer karty';
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wprowadź dane płatności'),
      backgroundColor: HiveColors.main,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: InputDecoration(
              labelText: 'Numer karty',
              errorText: _cardNumberError,
            ),
          ),
          TextField(
            controller: _expiryDateController,
            decoration: const InputDecoration(labelText: 'Data ważności (MM/RR)'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]+$')),
              LengthLimitingTextInputFormatter(5),
            ],
          ),
          TextField(
            controller: _cvvController,
            decoration: const InputDecoration(labelText: 'CVV'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
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
            if (!_validateCardNumber()) return;

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