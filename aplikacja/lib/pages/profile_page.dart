import 'dart:convert';
import 'dart:io';
import 'package:Hive/styles/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_page.dart';
import '../database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'event_page.dart';
import "package:flutter/material.dart";
import '../models/event.dart';
import '../pages/event_page.dart';
import '../styles/text_styles.dart';
import '../styles/hive_colors.dart';

/// Strona profilu użytkownika
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<dynamic>? userEvents = [];
  int? userId;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserEvents();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Brak tokena w SharedPreferences");
      }

      final data = await DatabaseHelper.getUserByToken(token);

      // Odczytaj ścieżkę do zdjęcia z SharedPreferences
      final profileImagePath = prefs.getString('profileImagePath');
      File? profileImage;
      if (profileImagePath != null) {
        profileImage = File(profileImagePath);
      }

      setState(() {
        userData = data;
        userId = data?['id'];
        _localImage = profileImage; // Ustaw lokalny obraz
      });
    } catch (e) {
      print('Błąd podczas pobierania danych użytkownika: $e');
    }
  }

  Future<void> _fetchUserEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("Brak tokena w SharedPreferences");
        return;
      } else {
        print("Token znaleziony: $token");
      }

      // Ignorowanie błędów certyfikatu (TYLKO NA TESTY!)
      final ioc = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final httpClient = IOClient(ioc);

      final response = await httpClient.get(
        Uri.parse('https://212.127.78.92:5000/user_events'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Kod odpowiedzi: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> events = jsonDecode(response.body);
        setState(() {
          userEvents = events;
        });
      } else {
        throw Exception(
            "Błąd podczas pobierania wydarzeń: ${response.statusCode}");
      }
    } catch (e) {
      print('Błąd podczas pobierania wydarzeń: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      await _saveImageLocally(file);
    }
  }

  Future<void> _resetToDefaultImage() async {
    // Ścieżka do domyślnego obrazu w assets
    final ByteData data = await rootBundle.load('assets/default_avatar.png');
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/default_avatar.png');
    await file.writeAsBytes(data.buffer.asUint8List());

    setState(() {
      _localImage = file;
    });

    // Zapisz ścieżkę do zdjęcia w SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', file.path);
  }

  Future<void> _saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final File newImage =
        await image.copy('${directory.path}/profile_image.png');

    setState(() {
      _localImage = newImage;
    });

    // Zapisz ścieżkę do zdjęcia w SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', newImage.path);

    // Opcjonalnie: zaktualizuj obraz w interfejsie
    setState(() {
      userData?['profileImage'] = newImage.path;
    });
  }

  Future<void> _uploadNewProfilePicture(BuildContext context) async {
    try {
      // Jeśli obraz lokalny jest ustawiony, użyj go do przesłania
      if (_localImage != null) {
        final File file = _localImage!;

        // Pobierz token do uwierzytelnienia
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          throw Exception("Brak tokenu w SharedPreferences");
        }

        // TODO: to nie powinno być w database_helper?
        // Wyślij obraz na serwer
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://212.127.78.92:5000/upload_image'),
        )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath('image', file.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zdjęcie profilowe zostało zmienione!')),
          );

          // Opcjonalnie: zaktualizuj obraz w interfejsie
          setState(() {
            userData?['profileImage'] =
                '<ścieżka_na_serwerze>'; // Zaktualizuj, jeśli serwer zwraca URL
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Błąd podczas przesyłania zdjęcia')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie wybrano żadnego zdjęcia.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wystąpił błąd: $e')),
      );
    }
  }

  Future<void> _chooseImageSource(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Wybierz z galerii'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Resetuj do domyślnego'),
                onTap: () {
                  Navigator.pop(context);
                  _resetToDefaultImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Event> events = userEvents!
        .map((dynamic event) => Event.fromJson(event as Map<String, dynamic>))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // Pomarańczowe tło
          Container(
            color: Colors.orange,
            height: MediaQuery.of(context).size.height * 0.4,
          ),
          Column(
            children: [
              const SizedBox(height: 50), // Odstęp od góry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Zdjęcie profilowe
              GestureDetector(
                onTap: () => _chooseImageSource(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _localImage != null
                      ? FileImage(_localImage!)
                      : userData != null && userData!['profileImage'] != null
                          ? NetworkImage(
                              userData!['profileImage']) // Ładowanie z serwera
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Nazwa użytkownika
              Text(
                userData != null && userData!['nickName'] != null
                    ? userData!['nickName']
                    : 'Nie ustawiono',
                style: HiveTextStyles.title,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: (userEvents == null || userEvents!.isEmpty)
                      ? const Center(
                          child: Text(
                            'Brak przyszłych wydarzeń',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0, // Odstępy między kolumnami
                            mainAxisSpacing: 10.0, // Odstępy między wierszami
                            childAspectRatio:
                                1.0, // Równy stosunek szerokości do wysokości
                          ),
                          itemCount: userEvents!.length,
                          itemBuilder: (context, index) {
                            final event = Event.fromJson(
                                userEvents![index] as Map<String, dynamic>);

                            return GridTile(
                                child: Card(
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Container(
                                width: double.infinity, // Pełna szerokość
                                height: double.infinity, // Pełna wysokość
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  // Żółte tło całego GridTile
                                  borderRadius: BorderRadius.circular(
                                      10), // Zaokrąglone rogi
                                ),

                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // Wyśrodkowanie zawartości
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 160,
                                      // Szerokość kontenera (możesz dostosować)
                                      height: 160,
                                      // Wysokość kontenera (możesz dostosować)
                                      decoration: BoxDecoration(
                                        color: HiveColors.main,
                                        // Żółte tło kontenera
                                        borderRadius: BorderRadius.circular(
                                            10), // Zaokrąglenie rogów
                                      ),
                                      child: Center(
                                        // Wyśrodkowanie obrazu w kontenerze
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          // Zaokrąglenie rogów obrazu
                                          child: Image.asset(
                                            event
                                                .imagePath, // Ścieżka do obrazu
                                            fit: BoxFit
                                                .cover, // Dopasowanie obrazu do kontenera
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ));
                          },
                        ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
