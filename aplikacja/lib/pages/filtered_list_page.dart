import 'package:Hive/pages/event_page.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../widgets/event_list_tile.dart';

class FilteredListPage extends StatefulWidget {
  final List<Event> filteredEvents;
  final Function(Event) onUpdate;

  const FilteredListPage(
      {Key? key, required this.filteredEvents, required this.onUpdate})
      : super(key: key);

  @override
  _FilteredListPageState createState() => _FilteredListPageState();
}

class _FilteredListPageState extends State<FilteredListPage> {
  int selectedSortingType = 0;
  bool sortingAscending = true;

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

  void sortEventsByPrice(bool ascending) {
    setState(() {
      widget.filteredEvents.sort((a, b) =>
          ascending ? a.cena.compareTo(b.cena) : b.cena.compareTo(a.cena));
    });
  }

  void sortEventsByParticipants(bool ascending) {
    setState(() {
      widget.filteredEvents.sort((a, b) => ascending
          ? a.registeredParticipants.compareTo(b.registeredParticipants)
          : b.registeredParticipants.compareTo(a.registeredParticipants));
    });
  }

  void sortEventsByDate(bool ascending) {
    setState(() {
      widget.filteredEvents.sort((a, b) => ascending
          ? a.startDate.compareTo(b.startDate)
          : b.startDate.compareTo(a.startDate));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyniki wyszukiwania'),
      ),
      body: widget.filteredEvents.isEmpty
          ? const Center(
              child: Text(
                'Brak wyników',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: widget.filteredEvents.length,
              itemBuilder: (context, index) {
                final event = widget.filteredEvents[index];
                return EventListTile(
                    event: event,
                    onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EventPage(
                                      event: event,
                                      onUpdate: widget.onUpdate,
                                    )),
                          )
                        });
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showSortingModalBottomSheet,
        child: const Icon(Icons.import_export),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
