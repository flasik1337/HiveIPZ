import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Osbługa ikon w formacie svg
import '../database/database_helper.dart';
import 'home_page.dart';
import '../models/event.dart';
import 'registration.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            builder: (context) => HomePage(events: []),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFC300), // Zielony
                    Color(0xFFFBFBFB), // Niebieski
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFC300), // Zielony
                    Color(0xFFFBFBFB), // Niebieski
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hive',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _loginController,
                    decoration: InputDecoration(
                      labelText: 'Email / Nazwa użytkownika',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Hasło',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/change_password');
                    },
                    child: const Text('Zapomniałem hasła'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF000000), // Zielony tekst
                    ), // Zielony tekst
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFC300), // Zielony
                      foregroundColor: Colors.white,    // Białe litery
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: const Text('Zaloguj', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  const Text('lub zaloguj się przez'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset('assets/facebook_icon.svg', width: 35, height: 35),
                        onPressed: () {}, // Tutaj podpiąc logowanie przez Facebooka
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: SvgPicture.asset('assets/google_icon.svg', width: 35, height: 35),
                        onPressed: () {}, // Tutaj podpiąc logowanie przez Google
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Dołącz do nas!'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Zarejestruj się',
                          style: TextStyle(color: Color(0xFFFFC300)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}