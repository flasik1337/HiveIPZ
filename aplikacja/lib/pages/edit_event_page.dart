import 'package:Hive/database/database_helper.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../widgets/event_type_grid.dart';

/// Strona edycji wydarenia
class EditEventPage extends StatefulWidget {
  final Event event;  // Event, który ma być poddany edycji
  final Function(Event) onSave; // Funkcja zapisu wydarzenia

  const EditEventPage({Key? key, required this.event, required this.onSave})
      : super(key: key);

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxParticipantsController;
  late String _typeController;
  late DateTime _dateController;
  late TextEditingController _cenaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
    _typeController = widget.event.type;
    _cenaController = TextEditingController(text: widget.event.cena.toString());
    _dateController = widget.event.startDate;
    _maxParticipantsController = widget.event.maxParticipants != -1 ?
      TextEditingController(text: widget.event.maxParticipants.toString()) :
      TextEditingController(text: "");
  }

  Future<void> _openTypeSelector(BuildContext context) async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return EventTypeGrid(
          onEventTypeSelected: (String eventType) {
            Navigator.pop(context, eventType);
          },
        );
      },
    );

    if (selectedType != null) {
      setState(() {
        _typeController = selectedType;
      });
    }
  }

  Future<bool> _showDeleteEventDialog(BuildContext context) async {
    return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
          title: const Text("Potwierdź usunięcie wydarzenia"),
          content: const Text("Czy na pewno chcesz usunąć trwale wydarzenie? Tej operacji nie można cofnąć."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Usuń',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
    ) ?? false;
  }

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final shouldDelete = await _showDeleteEventDialog(context);
    if (shouldDelete) {
      DatabaseHelper.deleteEvent(eventId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wydarzenie zostało usunięte')),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj wydarzenie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nazwa wydarzenia'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Lokalizacja'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Opis'),
            ),
            TextFormField(
              controller: _cenaController,
              decoration: const InputDecoration(labelText: 'Cena wejścia (zł)'),
              keyboardType: TextInputType.number,
            ),
            TextButton(
              onPressed: () => _openTypeSelector(context),
              child: Text(
                'Zmień typ wydarzenia: ${_typeController}'
              ),
            ),
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dateController,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if(pickedDate != null) {
                  setState(() {
                    _dateController = pickedDate;
                  });
                }
              },
              child: Text(
                'Zmień datę wydarzenia: ${_dateController.day}.${_dateController.month}.${_dateController.year}.'
              ),
            ),
            TextFormField(
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maksymalna liczba uczestników'),
                validator: (newMaxParticipants) {
                  if (int.tryParse(newMaxParticipants!)! < widget.event.registeredParticipants) {
                    return("Limit uczestników jest mniejszy niż liczba zarejestrowanych");
                  }
                  // FIXME: intellij proponuje, żeby wrzucić mu tutaj return null i git, ale nie wiem czy to bezpieczne
                  return null;
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // zapis danych
                _saveChanges(
                  context,
                  _nameController.text,
                  _locationController.text,
                  _descriptionController.text,
                  _typeController,
                  _dateController,
                  int.tryParse(_maxParticipantsController.text) ?? -1,
                  double.tryParse(_cenaController.text) ?? 0.0,
                  );
              },
              child: const Text('Zapisz zmiany'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _deleteEvent(context, widget.event.id),
              child: const Text("Usuń wydarzenie"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(BuildContext context, String name, String location,
      String description, String type, DateTime date, int maxParticipants, double cena) async {
    final updatedEvent = Event(
      id: widget.event.id,
      //id pozostaje bez zmian
      name: name,
      location: location,
      description: description,
      type: type,
      startDate: date,
      updatedAt: DateTime.now(),
      maxParticipants: maxParticipants,
      registeredParticipants: widget.event.registeredParticipants,
      imagePath: widget.event.imagePath,
      // TODO: nazwa organizatora
      cena: cena,
      isPromoted: widget.event.isPromoted,
      
      
    );

    try {
      final eventData = {
        'name': name,
        'location': location,
        'description': description,
        'type': type,
        'start_date': date.toIso8601String(),
        'max_participants':maxParticipants,
        'registered_participants': widget.event.registeredParticipants,
        'image': widget.event.imagePath,
        'cena': cena,
        'is_promoted': widget.event.isPromoted,
      };
      await DatabaseHelper.updateEvent(widget.event.id, eventData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wydarzenie zaktualizowane pomyślnie!')),
      );
      widget.onSave(updatedEvent);
      Navigator.pop(context, updatedEvent);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać zmian: $e')),
      );
    }
  }
}