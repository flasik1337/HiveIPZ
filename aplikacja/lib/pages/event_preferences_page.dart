import 'package:flutter/material.dart';

class EventPreferencesPage extends StatefulWidget {
  const EventPreferencesPage({super.key});

  @override
  _EventPreferencesPageState createState() => _EventPreferencesPageState();
}

class _EventPreferencesPageState extends State<EventPreferencesPage> {
  final List<Map<String, dynamic>> eventTypes = [
    {'type': 'Domówka', 'icon': Icons.home},
    {'type': 'Koncert', 'icon': Icons.music_note},
    {'type': 'Wydarzenie plenerowe', 'icon': Icons.park},
    {'type': 'Klub', 'icon': Icons.nightlife},
    {'type': 'Sportowe', 'icon': Icons.sports_soccer},
    {'type': 'Kulturalne', 'icon': Icons.theater_comedy},
  ];

  final Set<String> selectedEvents = {};

  void _toggleSelection(String eventType) {
    setState(() {
      if (selectedEvents.contains(eventType)) {
        selectedEvents.remove(eventType);
      } else {
        selectedEvents.add(eventType);
      }
    });
  }

  void _savePreferences() {
    // Tu możesz dodać logikę zapisu do bazy danych
    print('Zapisano preferencje: $selectedEvents');
    Navigator.pop(context);
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
              onPressed: _savePreferences,
              child: const Text('Zapisz i kontynuuj'),
            ),
          ),
        ],
      ),
    );
  }
}
