import 'package:Hive/styles/hive_colors.dart';
import 'package:Hive/widgets/event_type_grid.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import '../pages/filtered_page.dart';
import '../pages/new_event_page.dart';
import '../pages/profile_page.dart';
import '../services/event_filter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _bottomCenaController = TextEditingController();
  final TextEditingController _upCenaController = TextEditingController();
  bool isSearching = false;
  int selectedSortingType = 0;
  bool sortingAscending = false;
  double searchBarWidth = 56;

  // FIXME daje tutaj przykładowe, żeby zobaczyć jak działa, trzeba to wyrzucić
  List<String> recentSearches = ['pudzian', 'kremówki', 'mariusz'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    isSearching = false;
    _fetchAllEvents(); // Wywołanie funkcji pobierającej dane
    _loadRecentSearches(); //pobranie poprzednich wyszukiwań
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

  // pobierz poprzednie wyszukiwania (zapis do konta użytkownika np. 5 ostatnich?)
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ??
          ['pudzian', 'kremówki', 'mariusz'];
    });
  }

  void sortEventsByPrice(bool ascending) {
    setState(() {
      events.sort((a, b) =>
          ascending ? a.cena.compareTo(b.cena) : b.cena.compareTo(a.cena));
    });
  }

  void sortEventsByParticipants(bool ascending) {
    setState(() {
      events.sort((a, b) => ascending
          ? a.registeredParticipants.compareTo(b.registeredParticipants)
          : b.registeredParticipants.compareTo(a.registeredParticipants));
    });
  }

  void sortEventsByDate(bool ascending) {
    setState(() {
      events.sort((a, b) => ascending
          ? a.startDate.compareTo(b.startDate)
          : b.startDate.compareTo(a.startDate));
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchBarWidth = isSearching ? MediaQuery.of(context).size.width - 32 : 56;
      if (!isSearching) _searchController.clear();
    });
  }

  void _onSearch(String query) {
    EventFilterService.filterEventsByQuery(context, events, query);
    setState(() {
      isSearching = false;
    });
  }

  void showFilterModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
          child: Column(
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
                            EventFilterService.filterEventsByType(
                                context, events, typeFilter);
                          });
                        });
                  }),
              ListTile(
                title: const Text('Data'),
                onTap: () {
                  Navigator.pop(context);
                  EventFilterService.showDateFilterDialog(context, events);
                },
              ),
              ListTile(
                  title: const Text('Lokalizacja'),
                  onTap: () async {
                    Navigator.pop(context);
                    EventFilterService.showLocationFilterDialog(
                        context, events);
                  }),
              ListTile(
                  title: const Text('Cena'),
                  onTap: () async {
                    Navigator.pop(context);
                    EventFilterService.showPriceFilterDialog(context, events);
                  })
            ],
          ),
        );
      },
    );
  }

  void showSortingModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sortuj według:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // proponowane (domyślne), id = 0, (bez porządku, bo jedyny porządek to taki, że dajemy najfajniesze capiche?)
                  ListTile(
                    title: const Text('Proponowane'),
                    tileColor: selectedSortingType == 0
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    onTap: () {
                      setModalState(() {
                        selectedSortingType = 0;
                      });
                      // w tym miejscu funkcja sortująca po proponowanych
                    },
                  ),
                  // po cenie, id=1
                  ListTile(
                    title: const Text('Cena'),
                    tileColor: selectedSortingType == 1
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    trailing: selectedSortingType == 1
                        ? Icon(sortingAscending
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down)
                        : null,
                    onTap: () {
                      setModalState(() {
                        if (selectedSortingType != 1) {
                          sortingAscending = false;
                          selectedSortingType = 1;
                        } else {
                          sortingAscending = !sortingAscending;
                        }
                      });
                      sortEventsByPrice(sortingAscending);
                    },
                  ),
                  // po zapisanych uczestnikach, id=2
                  ListTile(
                    title: const Text('Zapisani uczestincy'),
                    tileColor: selectedSortingType == 2
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    trailing: selectedSortingType == 2
                        ? Icon(sortingAscending
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down)
                        : null,
                    onTap: () {
                      setModalState(() {
                        if (selectedSortingType != 2) {
                          sortingAscending = false;
                          selectedSortingType = 2;
                        } else {
                          sortingAscending = !sortingAscending;
                        }
                      });
                      sortEventsByParticipants(sortingAscending);
                    },
                  ),
                  // po dacie, id=3
                  ListTile(
                    title: const Text('Data'),
                    tileColor: selectedSortingType == 3
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    trailing: selectedSortingType == 3
                        ? Icon(sortingAscending
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down)
                        : null,
                    onTap: () {
                      setModalState(() {
                        if (selectedSortingType != 3) {
                          sortingAscending = false;
                          selectedSortingType = 3;
                        } else {
                          sortingAscending = !sortingAscending;
                        }
                      });
                      sortEventsByDate(sortingAscending);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
          // Przejdź do strony głównej
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(events: []),
            ),
          );
          break;
        case 1:
          // Hive (nic nie robi)
          break;
        case 2:
          // Dodawanie wydarzenia
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEventPage(onEventCreated: (newEvent) {
                setState(() {
                  events.add(newEvent);
                });
              }),
            ),
          );
          break;
        case 3:
          // Filtrowanie
          showFilterModalBottomSheet();
          break;
        case 4:
          // Profil użytkownika
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
      body: Stack(
        children: [
          // Główna zawartość strony
          events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchAllEvents,
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCard(
                        event: event,
                        onUpdate: (updatedEvent) {
                          setState(() {
                            events[index] = updatedEvent;
                          });
                        },
                      );
                    },
                  ),
                ),

          if (isSearching)
            Positioned(
                top: 50,
                right: 16,
                left: 16,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Szukaj...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: HiveColors.weakAccent,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: IconButton(
                        onPressed: _toggleSearch,
                        icon: Icon(Icons.clear, color: Colors.black),
                    ),
                  ),
                  onSubmitted: _onSearch,
                ),
            ),
          // FloatingActionButton w prawym górnym rogu
          if (!isSearching)
            Positioned(
              top: 50,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _toggleSearch,
                backgroundColor: Colors.amber,
                shape: const CircleBorder(),
                child: const Icon(Icons.search, color: Colors.black),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => _onBarTapped(0), // Strona główna
              icon: Icon(Icons.home, color: Colors.black),
            ),
            IconButton(
              onPressed: () => _onBarTapped(1), // Grywalizacja TODO
              icon: Icon(Icons.hive, color: Colors.black),
            ),
            FloatingActionButton(
              onPressed: () => _onBarTapped(2),
              // Dodawanie wydarzenia
              backgroundColor: Colors.amber,
              elevation: 10.0,
              // Wysokość unoszeinie się przycisku - tworzenie cienia
              child: Icon(
                Icons.add,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () => _onBarTapped(3), // Filtry
              icon: Icon(Icons.filter_alt_outlined, color: Colors.black),
            ),
            IconButton(
              onPressed: () => _onBarTapped(4), // Profil użytkownika
              icon: Icon(Icons.person, color: Colors.black),
            )
          ],
        ),
      ),
    );
  }
}
