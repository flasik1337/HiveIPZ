import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static const String link = 'http://100.106.3.180:5000';
  // static const String host = 'localhost';
  // static const int port = 3306;
  // static const String user = 'root';
  // static const String password = ''; // Dałem bez hasłowy dostęp bo i tak lokalnie
  // static const String db = 'projektIPZ'; // Nazwa bazydancych
  //
  // static Future<MySqlConnection> getConnection() async {
  //   final settings = ConnectionSettings(
  //     host: host,
  //     port: port,
  //     user: user,
  //     password: password,
  //     db: db,
  //   );
  //   return await MySqlConnection.connect(settings);
  // }
  static Future<void> addUser(
      String name,
      String surname,
      int age,
      String nickName,
      String email,
      String password,
      ) async {
    final url = Uri.parse('$link/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'age': age,
        'nickName': nickName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      print('Użytkownik zarejestrowany pomyślnie');
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>?> getUser(
      //String email, String password) async {
        String nickName, String password) async {
    final url = Uri.parse('$link/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      //body: jsonEncode({'email': email, 'password': password}),
        body: jsonEncode({'nickName': nickName, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    } else {
      final error = jsonDecode(response.body)['message'];
      throw Exception(error);
    }
  }
  // Update User by Patryk
  static Future<void> updateUser(
      String userId, Map<String, String> updatedFields) async {
    final url = Uri.parse('$link/update_user/$userId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedFields), // Dane do aktualizacji
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['message'] ??
          'Błąd podczas aktualizacji danych użytkownika';
      throw Exception(error);
    }
  }

  static Future<void> verifyToken(String token) async {
    final url = Uri.parse(
        '$link/verify_token'); // Zakładając, że endpoint to '/verify_token'
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Token jest ważny
      print('Token jest ważny');
    } else {
      // Token jest nieważny
      print('Token jest nieważny');
      throw Exception(
          'Token jest nieważny'); // Możesz obsłużyć błąd w inny sposób
    }
  }

  // Ściąganie hasła
  static Future<String?> fetchPassword(int userId, String token) async {
    final url = Uri.parse('$link/get_password/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['password'];
    } else {
      print('Error: ${response.body}');
      return null;
    }
  }

  // Zmiana hasła po starym haśle
  static Future<void> changePasswordWithOld(String oldPassword, String newPassword) async {
    print("DEBUG: stare hasło: $oldPassword");
    print("DEBUG: nowe hasło: $newPassword");
    final url = Uri.parse('$link/change_password_with_old');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': oldPassword, 'new_password': newPassword}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Błąd podczas zmiany hasła: $error');
    }
  }

  // Dodawanie wydarzeń
  static Future<void> addEvent(Map<String, dynamic> eventData) async {
    print("DEBUG: userId w dbhelper: ${eventData['user_id']}");
    final url = Uri.parse('$link/events');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventData),
    );
    if (response.statusCode == 201) {
      print('Wydarzenie dodane pomyślnie');
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
}


  // Aktualizowanie wydarzeń
  static Future<void> updateEvent(String id, Map<String, dynamic> eventData) async {
    final url = Uri.parse('$link/events/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      print('Wydarzenie zaktualizowane pomyślnie');
      print("Wysłane dane: $eventData");
    } else {
      print('Błąd: ${response.statusCode}, Treść odpowiedzi: ${response.body}');
      final error = jsonDecode(response.body)['error'] ?? 'Nieznany błąd';
      throw Exception(error);
    }

  }

  // Usuwanie wydarzeń
  static Future<void> deleteEvent(String id) async {
    final url = Uri.parse('$link/events/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      print('Wydarzenie usunięte pomyślnie');
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error);
    }
  }

  // Pobieranie wydarzenia
  static Future<Map<String, dynamic>?> getEvent(String id) async {
    final url = Uri.parse('$link/events/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['event'];
    } else {
      final error = jsonDecode(response.body)['message'];
      throw Exception(error);
    }
  }

  //Pobieranie wszystkich wydarzeń
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    var url = Uri.parse('$link/events');

    print("\nDEBUG: Wysyłanie zapytania do $url");
    final response = await http.get(url);
    print('DEBUG: Status code: ${response.statusCode}');
    print('DEBUG: Odpowiedź serwera: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Błąd parsowania odpowiedzi JSON: $e');
        throw Exception('Błąd parsowania danych wydarzeń');
      }
    } else {
      try {
        final error = jsonDecode(response.body)['error'];
        throw Exception('Błąd serwera: $error');
      } catch (e) {
        throw Exception('Błąd serwera: nieoczekiwany format odpowiedzi');
      }
    }
  }



  static Future<void> deleteAccount(String token) async {
    final url = Uri.parse('$link/delete_account');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print('Konto zostało usunięte');
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error);
    }
  }

  static Future<bool> verifyPassword(String token, String password) async {
    final url = Uri.parse('$link/verify_password');
    print(token);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'password': password}),
    );

    if (response.statusCode == 200) {
      return true; // Hasło jest poprawne
    } else if (response.statusCode == 401) {
      return false; // Nieprawidłowe hasło
    } else {
      throw Exception('Błąd serwera: ${response.statusCode}');
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Zakładam, że token jest przechowywany pod kluczem 'token'
  }

  static Future<void> joinEvent(String eventId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Brak tokenu sesji. Użytkownik nie jest zalogowany.');
    }

    final url = Uri.parse('$link/events/$eventId/join');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Dołączono do wydarzenia');
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Nieznany błąd';
      throw Exception('Błąd przy zapisie na wydarzenie: $error');
    }
  }

  static Future<void> leaveEvent(String eventId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Brak tokenu sesji. Użytkownik nie jest zalogowany.');
    }

    final url = Uri.parse('$link/events/$eventId/leave');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Opuszczono wydarzenie');
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Nieznany błąd';
      throw Exception('Błąd przy wypisie z wydarzenia: $error');
    }
  }

  static Future<String> getUserIdFromToken() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Brak tokenu sesji. Użytkownik nie jest zalogowany.');
    }

    final url = Uri.parse('$link/verify_token');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('DEBUG: Odpowiedź serwera: ${response.body}'); // Debuguj odpowiedź serwera

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userId = data['user_id'];
      if (userId == null) {
        throw Exception('Brak user_id w odpowiedzi serwera.');
      }
      return userId.toString(); // Upewnij się, że zawsze zwracany jest String
    } else {
      throw Exception('Błąd przy pobieraniu userId z tokenu.');
    }
  }

  // Sprawdzanie czy user już się zapisał na wydazenie
  static Future<bool> isUserJoinedEvent(String eventId, String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Brak tokenu sesji.');
    }

    final url = Uri.parse('$link/events/$eventId/check');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_joined'] as bool; // Oczekujemy odpowiedzi serwera z kluczem 'is_joined'
    } else {
      throw Exception('Błąd przy sprawdzaniu statusu użytkownika.');
    }
  }
  // Sprawdzamy czy user jest adminem wydarzenia
  static Future<bool> isAdmin(String eventId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Brak tokenu sesji.');
    }

    final url = Uri.parse('$link/events/$eventId/is_admin');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_admin'] as bool; // Oczekujemy odpowiedzi serwera z kluczem 'is_admin'
    } else {
      throw Exception('Błąd przy sprawdzaniu uprawnień administratora.');
    }
  }

  // Czesć patrykowa id usera po tokenie
  static Future<Map<String, dynamic>?> getUserByToken(String token) async {
    final url = Uri.parse('$link/get_user_by_token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    } else {
      final error = jsonDecode(response.body)['message'];
      throw Exception(error);
    }
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("Brak tokena, użytkownik już jest wylogowany.");
    }

    final url = Uri.parse('$link/logout');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await prefs.remove('token'); // Usuń token z pamięci lokalnej
    } else {
      final error =
          jsonDecode(response.body)['message'] ?? 'Błąd podczas wylogowywania';
      throw Exception(error);
    }
  }


}

