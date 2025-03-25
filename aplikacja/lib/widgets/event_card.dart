import "package:flutter/material.dart";
import '../models/event.dart';
import '../pages/event_page.dart';
import '../styles/text_styles.dart';

/// Widget realizujący pojedynczą karte wydarzenia widoczną w rolce
class EventCard extends StatelessWidget {
  final Event event;
  final int dateDiffrence;
  final Function(Event) onUpdate; //metoda do aktualizacji strony

  EventCard({
    super.key, required this.event, required this.onUpdate,
  }) : dateDiffrence = -DateTime.now()
      .difference(DateTime(event.startDate.year, event.startDate.month, event.startDate.day))
      .inDays;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EventPage(event: event,onUpdate: onUpdate,)
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Obrazek, tło
          Image.asset(
            event.imagePath,
            fit: BoxFit.cover,
          ),
          // Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: HiveTextStyles.title,
                ),
                Text(
                  dateDiffrence <= 0 ?
                      'Dzisiaj  |  ${event.location}'
                      : 'Za $dateDiffrence dni  |  ${event.location}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "ID: ${event.id}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          if (event.isPromoted)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Wydarzenie promowane',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),


        ],
      ),
    );
  }
}