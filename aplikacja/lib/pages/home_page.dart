import 'package:Hive/widgets/event_type_grid.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import '../pages/filtered_page.dart';
import '../pages/new_event_page.dart';
import '../pages/profile_page.dart';


/// Strona główna realizująca ideę rolek z wydarzeniami
class HomePage extends StatefulWidget {
  final List<Event> events;


  const HomePage({super.key, required this.events});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> events = [];
  int _selectedFromBottomBar = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllEvents(); // Wywołanie funkcji pobierającej dane
  }

  // Pobieranie wydarzeń z bazy
  Future<void> _fetchAllEvents() async {
    try {
      final eventsData = await DatabaseHelper.getAllEvents();
      setState(() {
        events = eventsData.map((data) => Event.fromJson(data)).toList();
      });
    } catch (e) {
      print('Błąd podczas pobierania danych wydarzeń: $e');
    }
  }

  /// Funkcja wyszukuje eventy ze słowem kluczowym w nazwie/lokalizacji i otweira filtered page ze znalezionymi wynikami
  /// args:
  ///   String query: hasło kluczowe do wyszukania
  void _filterEventsByQuery(String query) {
    query = query.trim(); // Usuń zbędne spacje
    print('Debug: Wartość query po trim = "$query"'); // Debugowanie

    if (query.isEmpty) {
      print('Debug: Pole wyszukiwania jest puste.'); // Debugowanie
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Pole wyszukania nie może być puste.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          );
        },
      );
      return;
    }

    // Filtracja wydarzeń
    final filteredEvents = events
        .where((event) =>
    event.name.toLowerCase().contains(query.toLowerCase()) ||
        event.location.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredEvents.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Nie znaleziono żadnych wydarzeń.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          );
        },
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
          FilteredPage(
            filteredEvents: filteredEvents,
            onUpdate: (updatedEvent) {
              setState(() {
                final index =
                events.indexWhere((event) => event.id == updatedEvent.id);
                if (index != -1) {
                  events[index] = updatedEvent;
                }
              });
            },
          ),
      ),
    );
  }


  void _filterEventsByType(String typeFilter, String query) {
    final filteredEvents = events
        .where((event) =>
        event.type.toLowerCase().contains(typeFilter.toLowerCase()))
        .toList();

    if (filteredEvents.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Nie znaleziono żadnych wydarzeń.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          );
        },
      );
      return;
    }
  }




  void _filterEventsByDate(DateTime dateFilter, String query) {
    final filteredEvents = events
        .where((event) =>
    event.startDate.year == dateFilter.year &&
        event.startDate.month == dateFilter.month &&
        event.startDate.day == dateFilter.day)
        .toList();

    if (filteredEvents.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Nie znaleziono żadnych wydarzeń.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  /// Otwieranie okna dialogowego z wyszukiwaniem
  void _showSearchDialog({bool onlyLocation = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wyszukiwanie wydarzeń'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: onlyLocation
                  ? 'Wprowadź lokalizację'
                  : 'Wprowadź nazwę lub lokalizację',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _searchController.clear();
              },
              child: const Icon(Icons.cancel)
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _filterEventsByQuery(_searchController.text);
                _searchController.clear(); // Wyczyść pole
              },
              child: const Icon(Icons.search),
            ),

          ],
        );
      }
    );
  }

  /// Obsługa NavigationBara na dole ekranu
  /// args:
  ///   int index: wybrany przycisk
  void _onBarTapped(int index) {
    setState(() {
      _selectedFromBottomBar = index;
      switch (_selectedFromBottomBar) {
        case 0:
          _showSearchDialog();
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                CreateEventPage(
                  onEventCreated: (newEvent) {
                    setState(() {
                      events.add(newEvent);
                      // _filteredEvents = widget.events;
                    });
                  }
                ),
            ),
          );
          break;
        case 2:
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filtruj po:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListTile(
                        title: const Text('Typ wydarzenia'),
                        onTap: () async {
                          Navigator.pop(context);
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return EventTypeGrid(
                                    onEventTypeSelected: (String typeFilter) {
                                      _filterEventsByType(typeFilter, "");
                                    });
                              });
                        }
                    ),
                    ListTile(
                        title: const Text('Data'),
                        onTap: () async {
                          Navigator.pop(context);
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            _filterEventsByDate(pickedDate, "");
                          }
                        }
                    ),
                    ListTile(
                        title: const Text('Lokalizacja'),
                        onTap: () async {
                          Navigator.pop(context);
                          _showSearchDialog(onlyLocation: true);
                        }
                    )
                  ]
              );
            },
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(),
            ),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strona Główna'),
        centerTitle: true, // Wyśrodkowanie tytułu
      ),
      body: events.isEmpty
          ? const Center(
        child: CircularProgressIndicator(), // Wyświetlanie ładowania, jeśli lista jest pusta
      )
          : RefreshIndicator(
        onRefresh: _fetchAllEvents, // Funkcja do odświeżania
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: events.length, // Liczba wydarzeń
          itemBuilder: (context, index) {
            final event = events[index]; // Pobranie konkretnego wydarzenia
            return EventCard(
              event: event,
              onUpdate: (updatedEvent) {
                setState(() {
                  events[index] = updatedEvent; // Aktualizacja wydarzenia
                });
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        enableFeedback: false,
        backgroundColor: Colors.black54,
        currentIndex: _selectedFromBottomBar,
        onTap: _onBarTapped,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'dołącz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_alt_outlined),
            label: 'filtruj',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'profil',
          ),
        ],
      ),
    );
  }
}