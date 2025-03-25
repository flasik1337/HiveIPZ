import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:Hive/database/database_helper.dart';


class EventPreferencesPage extends StatefulWidget {
  final String userId;

  const EventPreferencesPage({super.key, required this.userId});

  @override
  _EventPreferencesPageState createState() => _EventPreferencesPageState();
}


class _EventPreferencesPageState extends State<EventPreferencesPage> {
  final List<Map<String, dynamic>> eventTypes = [
  {'type': 'Domówka', 'icon': Icons.weekend},
  {'type': 'Warsztaty', 'icon': Icons.precision_manufacturing},
  {'type': 'Impreza masowa', 'icon': Icons.groups},
  {'type': 'Sportowe', 'icon': Icons.fitness_center},
  {'type': 'Kulturalne', 'icon': Icons.theater_comedy},
  {'type': 'Spotkanie towarzyskie', 'icon': Icons.sports_bar},
  {'type': 'Outdoor', 'icon': Icons.hiking},
  {'type': 'Relaks', 'icon': Icons.self_improvement},
  {'type': 'Firmowe', 'icon': Icons.apartment},
  {'type': 'Motoryzacyjne', 'icon': Icons.directions_car},
  ];

  final Set<String> selectedEvents = {};
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  _loadUserPreferences();
}

  

  void _toggleSelection(String eventType) {
    setState(() {
      if (selectedEvents.contains(eventType)) {
        selectedEvents.remove(eventType);
      } else {
        selectedEvents.add(eventType);
      }
    });
  }

  Future<void> _loadUserPreferences() async {
  try {
    final prefs = await DatabaseHelper.getUserEventPreferences(widget.userId);
    setState(() {
      selectedEvents.addAll(prefs);
      isLoading = false;
    });
  } catch (e) {
    print("Błąd podczas ładowania preferencji: $e");
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wybierz typy wydarzeń')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Wybierz, jakie typy wydarzeń Cię interesują:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: eventTypes.length,
              itemBuilder: (context, index) {
                final eventType = eventTypes[index]['type']!;
                final IconData icon = eventTypes[index]['icon']!;
                final isSelected = selectedEvents.contains(eventType);

                return GestureDetector(
                  onTap: () => _toggleSelection(eventType),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.withOpacity(0.7) : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 40, color: isSelected ? Colors.black : Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          eventType,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await DatabaseHelper.updateUserEventPreferences(widget.userId, selectedEvents.toList());
                  await DatabaseHelper.setUserPreferences(widget.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferencje zapisane')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(events: [])),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd zapisu preferencji: $e')),
                  );
                }
              },

              child: const Text('Zapisz i kontynuuj'),
            ),
          ),
        ],
      ),
    );
  }
}
