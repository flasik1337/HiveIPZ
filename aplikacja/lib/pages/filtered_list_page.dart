import 'package:Hive/pages/event_page.dart';
import 'package:Hive/services/event_sorter_service.dart';
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
        onPressed: () {
          EventSorterService.showSortingModalBottomSheet(
            context: context,
            events: widget.filteredEvents,
            refresh: () => setState(() {}),
            selectedSortingType: selectedSortingType,
            sortingAscending: sortingAscending,
            onSortingChanged: (type, ascending) {
              setState(() {
                selectedSortingType = type;
                sortingAscending = ascending;
              });
            },
          );
        },
        child: const Icon(Icons.import_export),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
