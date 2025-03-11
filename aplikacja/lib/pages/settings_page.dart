import 'package:biometric_login/biometric_login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../pages/password_change_page.dart';

/// Strona ustawień użytkownika
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userData;
  int? userId;
  final TextEditingController _passwordController = TextEditingController();
  bool showPasswordField = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // TODO: Implementacja logowania przy pomocy biometrii
  // Funkcja odpowiadająca za logowanie przy pomocy biometrii lub jeśli nie dostępna pinem
  Future<bool> _isBiometricAvailable() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;
    List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  // Nowa metoda nawigacji do strony konfiguracji 2FA
  void _navigateTo2FASetup() async {
    final hasBiometrics = await _isBiometricAvailable();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TwoFactorAuthPage(
          hasBiometrics: hasBiometrics,
        ),
      ),
    );
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
        userId = data?['id']; // Pobierz ID użytkownika
      });
    } catch (e) {
      print('Błąd podczas pobierania danych użytkownika: $e');
    }
  }

  // Funkcja usuwania konta
  Future<void> _deleteAccount(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final password = _passwordController.text.trim();

    if (token == null || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź hasło')),
      );
      return;
    }

    try {
      final isPasswordCorrect =
          await DatabaseHelper.verifyPassword(token, password);
      if (!isPasswordCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nieprawidłowe hasło')),
        );
        return;
      }

      final shouldDelete = await _showConfirmationDialog(context);
      if (shouldDelete) {
        await DatabaseHelper.deleteAccount(token);
        prefs.remove('token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto zostało usunięte')),
        );
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    }
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Wylogowanie'),
              content: const Text('Czy na pewno chcesz się wylogować?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Wyloguj'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final shouldLogout = await _showLogoutConfirmationDialog(context);
    if (shouldLogout) {
      try {
        await DatabaseHelper.logoutUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wylogowano pomyślnie')),
        );
        Navigator.pushReplacementNamed(
            context, '/sign_in'); // Powrót do ekranu logowania
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Potwierdzenie usunięcia konta'),
              content: const Text(
                'Czy na pewno chcesz usunąć swoje konto? Operacji nie można cofnąć.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Usuń',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _showEditDialog(String field, String initialValue) async {
    TextEditingController controller =
        TextEditingController(text: initialValue);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edytuj $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Nowe $field'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedValue = controller.text.trim();
                if (updatedValue.isNotEmpty) {
                  try {
                    await DatabaseHelper.updateUser(
                      userId!.toString(), // Konwersja userId na String
                      {field: updatedValue}, // Klucz i nowa wartość
                    );
                    Navigator.of(context).pop();
                    _fetchUserData(); // Odśwież dane
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('$field zaktualizowane pomyślnie')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd: $e')),
                    );
                  }
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null || userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Ustawienia ogólne'),
          ),
          Divider(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Weryfikacja dwuetapowa'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _navigateTo2FASetup,
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              // Obsługa kliknięcia w ustawienia profilu
            },
          ),
          Divider(),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Imię'),
                Text(userData!['imie'] ?? 'Nie ustawiono'),
              ],
            ),
            onTap: () => _showEditDialog('imie', userData!['imie'] ?? ''),
          ),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nazwisko'),
                Text(userData!['nazwisko'] ?? 'Nie ustawiono'),
              ],
            ),
            onTap: () =>
                _showEditDialog('nazwisko', userData!['nazwisko'] ?? ''),
          ),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Login'),
                Text(userData!['nickName'] ?? 'Nie ustawiono'),
              ],
            ),
            onTap: () =>
                _showEditDialog('nickName', userData!['nickName'] ?? ''),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () {
                if (userId != null && userData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordChangePage(),
                    ),
                  );
                }
              },
              child: const Text('Zmień hasło')),
          Divider(),
          if (showPasswordField) ...[
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Podaj swoje hasło',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _deleteAccount(context),
              child: const Text('Potwierdź usunięcie konta'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showPasswordField = true;
                });
              },
              child: const Text('Usuń konto'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _confirmAndLogout(context),
              icon: const Icon(
                Icons.logout,
                color: Colors.black, // Kolor ikony na czarny
              ),
              label: const Text(
                'Wyloguj się',
                style: TextStyle(
                  color: Colors.black, // Kolor tekstu na czarny
                  fontWeight: FontWeight.bold, // Ustawienie grubszego tekstu
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TwoFactorAuthPage extends StatefulWidget {
  final bool hasBiometrics;

  const TwoFactorAuthPage({
    Key? key,
    required this.hasBiometrics,
  }) : super(key: key);

  @override
  _TwoFactorAuthPageState createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  bool _isBiometricEnabled = false;
  String _pin = '';
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled_') ?? false;
      _pin = prefs.getString('pin_') ?? '';
    });
  }
 //TODO: Jeżeli jest już ustawiony PIN, możliwość zmiany go !!!Podanie starego PINu!!!
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_', _isBiometricEnabled);
    await prefs.setString('pin_', _pin);
  }

  Future<void> _authenticateBiometric() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool authenticated = await auth.authenticate(
      localizedReason: 'Włącz weryfikację biometryczną',
    );

    if (authenticated) {
      setState(() {
        _isBiometricEnabled = true;
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weryfikacja dwuetapowa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metody weryfikacji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Opcja biometrii
            if (widget.hasBiometrics)
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Weryfikacja biometryczna'),
                trailing: Switch(
                  value: _isBiometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _authenticateBiometric();
                    } else {
                      setState(() {
                        _isBiometricEnabled = false;
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),

            // Opcja PINu
            const SizedBox(height: 16),
            const Text(
              'Kod PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Wprowadź nowy PIN (4 cyfry)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.length == 4) {
                  setState(() {
                    _pin = value;
                  });
                  _saveSettings();
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _pin.isNotEmpty ? 'PIN zapisany' : 'Brak zapisanego PINu',
              style: TextStyle(color: _pin.isNotEmpty ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

