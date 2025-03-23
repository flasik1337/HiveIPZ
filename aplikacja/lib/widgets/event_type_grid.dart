import 'package:flutter/material.dart';
import '../models/event.dart';

/// Widżet realizujący siatkę wyboru pojedynczego typu wydarzenia
class EventTypeGrid extends StatelessWidget {
  final void Function(String) onEventTypeSelected;

  EventTypeGrid({super.key, required this.onEventTypeSelected});

  final List<Map<String, String>> eventTypes = [
    {'type': 'Domówka', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Warsztaty', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Impreza masowa', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Sportowe', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Kulturalne', 'icon': 'assets/icons/default_avatar.png'},
    {
      'type': 'Spotkanie towarzyskie',
      'icon': 'assets/icons/default_avatar.png'
    },
    {'type': 'Outdoor', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Relaks', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Firmowe', 'icon': 'assets/icons/default_avatar.png'},
    {'type': 'Motoryzacyjne', 'icon': 'assets/icons/default_avatar.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: eventTypes.length,
        itemBuilder: (context, index) {
          final eventType = eventTypes[index];
          return GestureDetector(
            onTap: () {
              onEventTypeSelected(eventType['type']!);
            },
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Event.getIcon(eventType['type']!),
                ),
                const SizedBox(height: 8),
                Text(
                  eventType['type']!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
