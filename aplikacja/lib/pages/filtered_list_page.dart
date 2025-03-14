import 'package:Hive/pages/event_page.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';

class FilteredListPage extends StatelessWidget {
  final List<Event> filteredEvents;
  final Function(Event) onUpdate;

  const FilteredListPage(
      {Key? key, required this.filteredEvents, required this.onUpdate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Wyniki wyszukiwania'),
        ),
        body: filteredEvents.isEmpty
            ? const Center(
                child: Text(
                  'Brak wyników',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              )
            : ListView.separated(
                itemCount: filteredEvents.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.grey,
                  thickness: 1,
                  height: 10
                ),
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return ListTile(
                      title: Text('${event.name} | ${event.location}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EventPage(
                                    event: event,
                                    onUpdate: onUpdate,
                                  )),
                        );
                      });
                },
              ));
  }
}
