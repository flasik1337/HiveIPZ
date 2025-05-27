import 'package:Hive/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../main.dart';
import '../pages/event_preferences_page.dart';

class GoogleService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '161099687654-094psfarrpc03dm0rmpcmv0oe55dsna3.apps.googleusercontent.com'
  );

  static Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Logowanie anulowane');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Brak tokenu ID');

      // Wywołujemy metodę z DatabaseHelper
      await DatabaseHelper.loginWithGoogle(idToken).then((userData) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', userData['token']);
        await prefs.setString('userId', userData['user']['id'].toString());

        bool hasPreferences = await DatabaseHelper.getUserPreferences(userData['user']['id'].toString());

        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
              builder: (context) => hasPreferences
                  ? HomePage(events: [],)
                  : EventPreferencesPage(userId: userData['user']['id'].toString()),
          ),
        );
      });
    } catch (e) {
      print('Błąd logowania Google: $e');
    }
  }
}
