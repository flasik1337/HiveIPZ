import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'home_page.dart';
import '../models/event.dart';
import 'registration.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Strona logowania
class SignInPage extends StatefulWidget {
  final List<Event> events;
  final String? errorMessage;

  const SignInPage({Key? key, required this.events, this.errorMessage}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Wyświetlenie SnackBar z błędem, jeśli sesja wygasła
    if (widget.errorMessage != null) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.errorMessage!)),
        );
      });
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _signIn() async {
    // NOTE: nickname to wszędzie login tylko nie zostało to zmienione w bazie danych
    final nickName = _loginController.text;
    final password = _passwordController.text;

    if (nickName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź login i hasło')),
      );
      return;
    }

    try {
      final userData = await DatabaseHelper.getUser(nickName, password);

      if (userData != null) {
        final token = userData['token'];
        await saveToken(token); // Zapis tokenu

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zalogowano pomyślnie')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(events: [],),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nieprawidłowe dane logowania')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Zaloguj się',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 50.0),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5.0),
              child: TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'login',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5.0),
              child: TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Hasło',
                ),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/change_password');
                },
                child: const Text(
                  'Nie pamiętam hasła',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ElevatedButton(
                onPressed: _signIn,
                child: const Text(
                  'Zaloguj',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
                  'Zarejestruj się',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}