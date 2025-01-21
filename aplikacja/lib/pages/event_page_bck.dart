import 'package:flutter/material.dart';
import '../models/event.dart';
import '../styles/gradients.dart';
import '../pages/edit_event_page.dart';
import '../database/database_helper.dart'; // Dodano do obsługi API

class EventPage extends StatefulWidget {
  final Event event;
  final Function(Event) onUpdate;

  const EventPage({super.key, required this.event, required this.onUpdate});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late Event _currentEvent; // aktualne wydarzenie
  bool _isUserJoined = false; // Czy użytkownik jest zapisany na wydarzenie

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _checkUserJoinedStatus(); // Sparawdzanie czy użytkownik jest zapisany na wydarzenie
    _checkIfUserIsAdmin(); // Sprawdzenie, czy użytkownik jest właścicielem wydarzenia
  }


  void _updateEvent(Event updatedEvent) {
    setState(() {
      _currentEvent = updatedEvent;
    });
  }

  // 20.10 20:38 -- dodanie sprawdzania czy użytkownik jest właścicielem wydarzenia
  bool _isUserAdmin = true;

  Future<void> _checkIfUserIsAdmin() async {
    try {
      final isAdmin = await DatabaseHelper.isAdmin(_currentEvent.id);
      setState(() {
        _isUserAdmin = isAdmin;
      });
    } catch (e) {
      print('Błąd podczas sprawdzania statusu administratora: $e');
    }
  }

  Future<void> _checkUserJoinedStatus() async {
    try {
      final userId = await DatabaseHelper.getUserIdFromToken();
      print('DEBUG: userId = $userId'); // Loguj userId

      final isJoined = await DatabaseHelper.isUserJoinedEvent(
          _currentEvent.id, userId);
      print('DEBUG: isUserJoined = $isJoined'); // Loguj status

      setState(() {
        _isUserJoined = isJoined;
      });
    } catch (e) {
      print('Błąd podczas sprawdzania statusu użytkownika: $e');
    }
  }


  Future<void> _joinOrLeaveEvent() async {
    try {
      if (_isUserJoined) {
        // Wypisanie z wydarzenia
        await DatabaseHelper.leaveEvent(_currentEvent.id);
        setState(() {
          _isUserJoined = false;
          _currentEvent = _currentEvent.copyWith(
            registeredParticipants: _currentEvent.registeredParticipants - 1,
          );
        });
      } else {
        // Zapisanie na wydarzenie
        await DatabaseHelper.joinEvent(_currentEvent.id);
        setState(() {
          _isUserJoined = true;
          _currentEvent = _currentEvent.copyWith(
            registeredParticipants: _currentEvent.registeredParticipants + 1,
          );
        });
      }
    } catch (e) {
      print('Błąd podczas zapisywania/wypisywania użytkownika: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double photoHeight = 300;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                _currentEvent.imagePath,
                height: photoHeight,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: photoHeight,
                decoration: BoxDecoration(
                  gradient: AppGradients.eventPageGradient,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  _currentEvent.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_currentEvent.location}  |  ${_currentEvent
                  .type}\n${_currentEvent.startDate.day}.${_currentEvent
                  .startDate.month}.${_currentEvent.startDate.year}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _currentEvent.maxParticipants != -1
                  ? '${_currentEvent.registeredParticipants} / ${_currentEvent
                  .maxParticipants}'
                  : 'Wydarzenie otwarte',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentEvent.description,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          // Wyświetl przycisk "Edytuj wydarzenie" tylko, jeśli użytkownik jest właścicielem wydarzenia
          if (_isUserAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _navigateToEditPage(context),
                child: const Text('Edytuj wydarzenie'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _joinOrLeaveEvent,
              child: Text(_isUserJoined ? 'Wypisz się' : 'Zapisz się'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPage(BuildContext context)
  {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: _currentEvent, onSave: (updatedEvent) {_updateEvent(updatedEvent);
        widget.onUpdate(updatedEvent);}), // Przekierowanie na stronę edycji
      ),
    );
  }
}