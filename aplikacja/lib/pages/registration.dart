import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _showPassword = false;


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final userNickname = _userNicknameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        // Dodaj użytkownika do bazy danych
        await DatabaseHelper.addUser(userNickname, email, password);

        // Wyświetl komunikat o powodzeniu i przejdź do ekranu logowania
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejestracja pomyślna!')),
        );
        Navigator.pushNamed(context, '/sign_in');
      } catch (e) {
        // Wyświetl komunikat o błędzie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd rejestracji: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _userNicknameController,
                decoration: const InputDecoration(labelText: 'Nick'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź nazwę użytkownika';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź adres email';
                  }
                  final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
                  if (!emailRegex.hasMatch(value)/*!value.contains('@')*/) {
                    return 'Wprowadź poprawny adres email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Hasło'),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź hasło';
                  }
                  if (_passwordConfirmController.text != _passwordController.text) {
                    return 'Hasła nie zgadzają się';
                  }
                  final passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*~_-]).{8,}$');
                  if (!passwordRegExp.hasMatch(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę i znak specjalny.',
                        ),
                      ),
                    );
                    return 'Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę i znak specjalny.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordConfirmController,
                decoration: const InputDecoration(labelText: 'Potwierdź hasło'),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź hasło';
                  }
                  if (_passwordConfirmController.text != _passwordController.text) {
                    return 'Hasła nie zgadzają się';
                  }
                  final passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*~_-]).{8,}$');
                  if (!passwordRegExp.hasMatch(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę i znak specjalny.',
                        ),
                      ),
                    );
                    return 'Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę i znak specjalny.';
                  }
                  return null;
                },
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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Zarejestruj się'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}