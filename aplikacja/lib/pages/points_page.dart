import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../styles/hive_colors.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({Key? key}) : super(key: key);

  @override
  _PointsPageState createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  Map<String, dynamic>? userData;
  int? userId;
  int? userPoints;
  List<Event>? userEvents; // Lista obiektów Event

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
        userPoints = data?['points'];
      });

      // Pobranie wydarzeń dla tego użytkownika
      if (userId != null) {
        final events = await DatabaseHelper.getUserEvents(userId!);
        setState(() {
          userEvents = events?.map((eventMap) {
            return Event(
              id: eventMap['id'],
              name: eventMap['name'],
              location: eventMap['location'],
              description: eventMap['description'],
              type: eventMap['type'],
              startDate: DateTime.parse(eventMap['start_date']),
              maxParticipants: eventMap['max_participants'],
              registeredParticipants: eventMap['registered_participants'],
              imagePath: eventMap['image'],
              userId: eventMap['user_id'],
              cena: double.tryParse(eventMap['cena'].toString()) ?? 0.0,
              isPromoted: eventMap['is_promoted'] == 1,
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Błąd podczas pobierania danych użytkownika: $e');
    }
  }

  // Funkcja do promowania wydarzenia
  Future<void> promoteEvent(Event event) async {
    if (userPoints! < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie masz wystarczająco punktów!')),
      );
      return;
    }

    // Zmniejszamy punkty użytkownika o 1000
    try {
      final updatedUser = userData!;
      updatedUser['points'] =
          userPoints! - 1000; // Zmniejszamy punkty użytkownika

      // Aktualizujemy dane użytkownika
      await DatabaseHelper.updateUser(
          userId.toString(), {'points': updatedUser['points'].toString()});

      // Używamy copyWith na obiekcie Event i zmieniamy isPromoted
      Event updatedEvent = event.copyWith(isPromoted: true);

      // Aktualizujemy wydarzenie w bazie danych
      await DatabaseHelper.updateEvent(event.id, {
        'name': event.name,
        'location': event.location,
        'description': event.description,
        'type': event.type,
        'start_date': event.startDate.toIso8601String(),
        'max_participants': event.maxParticipants,
        'registered_participants': event.registeredParticipants,
        'image': event.imagePath,
        'is_promoted': updatedEvent.isPromoted,
      });

      // Aktualizujemy stan aplikacji
      setState(() {
        userPoints = updatedUser['points'];
        final index = userEvents?.indexWhere((e) => e.id == event.id);
        if (index != null && index >= 0) {
          userEvents?[index] = updatedEvent;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wydarzenie zostało promowane!')),
      );
    } catch (e) {
      print("Błąd podczas promocji wydarzenia: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas promocji wydarzenia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: HiveColors.main,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: cardWidth,
              height: 160,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/honeycoins.png', // Zastąp nazwą swojego pliku PNG
                    height: 100, // Opcjonalnie, ustaw wysokość ikony
                    width: 100, // Opcjonalnie, ustaw szerokość ikony
                  ),
                  SizedBox(width: 10),
                  Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("HoneyCoins",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w200)),
                      Text(
                        userPoints?.toString() ?? '0',
                        style: TextStyle(
                          fontSize: 34,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2 // Dostosuj grubość obrysu
                            ..color = Colors.black, // Dostosuj kolor obrysu
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(120.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text("Lista nagród",
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: userEvents?.length ?? 0,
                        itemBuilder: (context, index) {
                          final event = userEvents?[index];

                          return GestureDetector(
                            onTap: () {
                              promoteEvent(event!);
                            },
                            child: Center(
                              child: Container(
                                width: cardWidth,
                                margin: EdgeInsets.only(bottom: 16.0),
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 32.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Promocja wydarzenia",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey)),
                                          Text(event?.name ?? 'Brak nazwy',
                                              style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -15,
                                      right: -15,
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        widthFactor:
                                            20.1, // Zmniejszamy, aby zwiększyć zaokrąglenie
                                        heightFactor:
                                            0.1, // Zmniejszamy, aby zwiększyć zaokrąglenie
                                        child: ClipOval(
                                          child: Container(
                                            width: 150,
                                            height: 150,
                                            decoration: BoxDecoration(
                                              color: Colors.yellow,
                                            ),
                                            child: Icon(Icons.trending_up,
                                                color: Colors.black, size: 40),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
