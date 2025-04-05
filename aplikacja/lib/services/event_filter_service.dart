import 'package:Hive/pages/filtered_list_page.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../widgets/event_type_grid.dart';

class EventFilterService {
  static void filterEventsByQuery(BuildContext context, List<Event> events, String query) {
    query = query.trim().toLowerCase();

    if (query.isEmpty) {
      _showErrorDialog(context, 'Pole wyszukiwania nie może być puste.');
      return;
    }

    final filteredEvents = events.where((event) =>
    event.name.toLowerCase().contains(query) ||
        event.location.toLowerCase().contains(query)).toList();

    _navigateToFilteredPage(context, filteredEvents);
  }

  static void filterEventsByType(BuildContext context, List<Event> events, String typeFilter) {
    final filteredEvents = events.where((event) =>
        event.type.toLowerCase().contains(typeFilter.toLowerCase())).toList();

    _navigateToFilteredPage(context, filteredEvents);
  }

  static void filterEventsByPrice(BuildContext context, List<Event> events, double priceBottom, double priceUp) {
    final filteredEvents = events.where((event) =>
    event.cena >= priceBottom && event.cena <= priceUp).toList();

    _navigateToFilteredPage(context, filteredEvents);
  }

  static void filterEventsByDate(BuildContext context, List<Event> events, DateTime dateBottom, DateTime dateUp) {
    final filteredEvents = events.where((event) =>
    event.startDate.isAfter(dateBottom) &&
        event.startDate.isBefore(dateUp)).toList();

    _navigateToFilteredPage(context, filteredEvents);
  }

  static void showLocationFilterDialog(BuildContext context, List<Event> events) {
    TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Podaj wyszukiwaną lokalizację'),
          content: TextField(
            controller: locationController,
            decoration: const InputDecoration(hintText: 'Lokalizacja'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                String locationQuery = locationController.text;
                filterEventsByQuery(context, events, locationQuery);
              },
              child: const Text('Szukaj'),
            )
          ]
        );
      }
    );
  }

  static void showPriceFilterDialog(BuildContext context, List<Event> events) {
    TextEditingController bottomController = TextEditingController();
    TextEditingController upController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Podaj przedział cenowy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bottomController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Dolna granica'),
              ),
              TextField(
                controller: upController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Górna granica'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                double bottom = double.tryParse(bottomController.text) ?? 0.0;
                double up = double.tryParse(upController.text) ?? double.infinity;
                filterEventsByPrice(context, events, bottom, up);
              },
              child: const Text('Filtruj'),
            ),
          ],
        );
      },
    );
  }

  static void showDateFilterDialog(BuildContext context, List<Event> events) {
    DateTime? dateBottom;
    DateTime? dateUp;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wybierz przedział dat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  dateBottom = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                },
                child: const Text('Wybierz datę początkową'),
              ),
              ElevatedButton(
                onPressed: () async {
                  dateUp = await showDatePicker(
                    context: context,
                    initialDate: dateBottom ?? DateTime.now(),
                    firstDate: dateBottom ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                },
                child: const Text('Wybierz datę końcową'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                if (dateBottom != null && dateUp != null) {
                  Navigator.pop(context);
                  filterEventsByDate(context, events, dateBottom!, dateUp!);
                }
              },
              child: const Text('Filtruj'),
            ),
          ],
        );
      },
    );
  }

  static void _navigateToFilteredPage(BuildContext context, List<Event> filteredEvents) {
    if (filteredEvents.isEmpty) {
      _showErrorDialog(context, 'Nie znaleziono żadnych wydarzeń.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredListPage(
          filteredEvents: filteredEvents,
          onUpdate: (updatedEvent) {},
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showFilterModalBottomSheet({
    required BuildContext context,
    required List<Event> events,

}) {
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
}
