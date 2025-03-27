import 'package:flutter/material.dart';
import '../models/event.dart';

class EventSorterService {
  static void sortByPrice(List<Event> events, bool ascending) {
    events.sort((a, b) =>
        ascending ? a.cena.compareTo(b.cena) : b.cena.compareTo(a.cena));
  }

  static void sortByParticipants(List<Event> events, bool ascending) {
    events.sort((a, b) => ascending
        ? a.registeredParticipants.compareTo(b.registeredParticipants)
        : b.registeredParticipants.compareTo(a.registeredParticipants));
  }

  static void sortByDate(List<Event> events, bool ascending) {
    events.sort((a, b) => ascending
        ? a.startDate.compareTo(b.startDate)
        : b.startDate.compareTo(a.startDate));
  }

  static void showSortingModalBottomSheet({
    required BuildContext context,
    required List<Event> events,
    required void Function() refresh,
    required int selectedSortingType,
    required bool sortingAscending,
    required void Function(int newType, bool newAscending) onSortingChanged,
  }) {
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
                  ListTile(
                    title: const Text('Proponowane'),
                    tileColor: selectedSortingType == 0
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    onTap: () {
                      setModalState(() {
                        onSortingChanged(0, true);
                      });
                      Navigator.pop(context);
                      refresh();
                    },
                  ),
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
                      final newAscending =
                          selectedSortingType == 1 ? !sortingAscending : false;
                      setModalState(() {
                        onSortingChanged(1, newAscending);
                      });
                      sortByPrice(events, newAscending);
                      Navigator.pop(context);
                      refresh();
                    },
                  ),
                  ListTile(
                    title: const Text('Zapisani uczestnicy'),
                    tileColor: selectedSortingType == 2
                        ? Colors.amber.withOpacity(0.3)
                        : null,
                    trailing: selectedSortingType == 2
                        ? Icon(sortingAscending
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down)
                        : null,
                    onTap: () {
                      final newAscending =
                          selectedSortingType == 2 ? !sortingAscending : false;
                      setModalState(() {
                        onSortingChanged(2, newAscending);
                      });
                      sortByParticipants(events, newAscending);
                      Navigator.pop(context);
                      refresh();
                    },
                  ),
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
                      final newAscending =
                          selectedSortingType == 3 ? !sortingAscending : false;
                      setModalState(() {
                        onSortingChanged(3, newAscending);
                      });
                      sortByDate(events, newAscending);
                      Navigator.pop(context);
                      refresh();
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
}
