import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'pages/sign_in.dart';
import 'pages/home_page.dart';
import 'pages/registration.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/password_reset_page.dart';
import 'models/event.dart';

// Przykładowe wydarzenia testowe
List<Event> testEvents = [
  // Event(
  //   id: "0",
  //   name: "Trening z Pudzianem",
  //   location: "Szczecin, siłownia ZUT",
  //   type: 'Warsztaty',
  //   startDate: DateTime(2025, 2, 14, 18, 0),
  //   maxParticipants: -1,
  //   registeredParticipants: 10,
  //   imagePath: "assets/pudzian0.jpg",
  // ),
  // Event(
  //   id: "1",
  //   name: "Walka z Pudzianem",
  //   location: "Blok 12, osiedle Kaliny",
  //   type: 'Sportowe',
  //   startDate: DateTime(2025, 1, 29, 19, 30),
  //   maxParticipants: 1,
  //   registeredParticipants: 0,
  //   imagePath: "assets/pudzian1.jpg",
  // ),
  // Event(
  //   id: "2",
  //   name: "Przejażdżka z Pudzianem",
  //   location: "Szczecin, Jezioro Głębokie",
  //   type: 'Motoryzacyjne',
  //   startDate: DateTime(2025, 1, 21),
  //   maxParticipants: 3,
  //   registeredParticipants: 1,
  //   imagePath: "assets/pudzian2.jpg",
  // ),
];


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');
  print("Odczytany token: $token"); // Sprawdź, czy token jest zapisany
  String? errorMessage;

  if (token != null) {
    try {
      await DatabaseHelper.verifyToken(token);
    } catch (e) {
      prefs.remove('token');
      token = null;
      errorMessage = 'Sesja wygasła, zaloguj się ponownie.';
    }
  }



  runApp(MyApp(
    initialRoute: token != null ? '/home' : '/sign_in',
    errorMessage: errorMessage,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String? errorMessage;

  const MyApp({super.key, required this.initialRoute, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
      ),
      initialRoute: initialRoute,
      routes: {
        '/sign_in': (context) => SignInPage(events: testEvents, errorMessage: errorMessage),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(events: testEvents),
        '/account': (context) => ProfilePage(),
        '/settings': (context) => SettingsPage(),
        '/change_password': (context) => PasswordResetPage(),
      },
    );
  }
}
