import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  Map<String, dynamic>? userData;
  int? userId;

  get http => null;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late String oldPassword;

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Brak tokena w SharedPreferences");
      }

      final data = await DatabaseHelper.getUserByToken(token);
      setState(() {
        userData = data;
        userId = data?['id'];
      });

      if (userId != null) {
        fetchCurrentPassword(token);
      }
    } catch (e) {
      print('Błąd podczas pobierania danych użytkownika: $e');
    }
  }

  void fetchCurrentPassword(String token) async {
    try {
      print("DEBUG: Pobieranie hasła dla userId: $userId z tokenem: ${userData!['token']}");
      final password = await DatabaseHelper.fetchPassword(userId!, token);
      print("DEBUG: Otrzymane hasło: $password");
      setState(() {
        oldPassword = password ?? '';
      });
    } catch (e) {
      print("Błąd podczas pobierania obecnego hasła: $e");
    }
  }


  Future<void> _changePassword() async {
    final currentPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wszystkie pola')),
      );
      return;
    }

    // Walidacja nowego hasła
    final passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*~_-]).{8,}$');
    if (!passwordRegExp.hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę i znak specjalny.',
          ),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasła się nie zgadzają')),
      );
      return;
    }

    if (newPassword == oldPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nowe hasło jest takie samo jak stare.')),
      );
      return;
    }

    try {
      await DatabaseHelper.changePasswordWithOld(oldPassword, newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasła zostało zmienione pomyślnie')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zmiany hasła: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (userData == null || oldPassword.isEmpty) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zmień hasło'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Aktualne hasło',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Nowe hasło',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Potwierdź nowe hasło',
                border: OutlineInputBorder(),
              ),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                      value: _showPassword,
                      onChanged: (value) {
                        setState(() {
                          _showPassword = value!;
                        });
                      }
                  ),
                  const Text("Pokaż hasło")
                ]
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Potwierdź'),
            ),
          ],
        ),
      ),
    );
  }
}