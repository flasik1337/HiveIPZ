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
  bool _isUserOwner = false; // Czy użytkownik jest właścicielem wydarzenia?
  String? _userId; // Przechowywanie userId


  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _initializeUser(); // Inicjalizacja użytkownika
  }

  Future<void> _initializeUser() async {
    try {
      _userId = await DatabaseHelper.getUserIdFromToken();
      print('DEBUG: userId = $_userId');
      _checkUserJoinedStatus();
      _checkIfUserIsOwner();
    } catch (e) {
      print('Błąd podczas inicjalizacji użytkownika: $e');
    }
  }
  void _updateEvent(Event updatedEvent) {
    setState(() {
      _currentEvent = updatedEvent;
    });
  }

  void _checkIfUserIsOwner() {
    if (_userId != null) {
      setState(() {
        _isUserOwner = _currentEvent.userId == int.tryParse(_userId!);
      });
      print('DEBUG: isUserOwner = $_isUserOwner');
    }
  }

  Future<void> _checkUserJoinedStatus() async {
    if (_userId != null) {
      try {
        final isJoined = await DatabaseHelper.isUserJoinedEvent(
            _currentEvent.id, _userId!);
        print('DEBUG: isUserJoined = $isJoined'); // Loguj status

        setState(() {
          _isUserJoined = isJoined;
        });
      } catch (e) {
        print('Błąd podczas sprawdzania statusu użytkownika: $e');
      }
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
        if (_currentEvent.maxParticipants != -1 &&
            _currentEvent.registeredParticipants >= _currentEvent.maxParticipants) {
          // Jeśli liczba uczestników osiągnęła maksymalny limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wydarzenie jest już pełne!'),
            ),
          );
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
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentEvent.cena > 0
                  ? 'Cena wejścia: ${_currentEvent.cena} zł'
                  : 'Wejście darmowe',
              style: const TextStyle(fontSize: 20, color: Colors.white),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _currentEvent.maxParticipants != -1
                  ? '${_currentEvent.registeredParticipants} / ${_currentEvent
                  .maxParticipants}'
                  : 'Wydarzenie otwarte, ${_currentEvent.registeredParticipants} uczestników',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
            ),
          ),
          // Wyświetl przycisk "Edytuj wydarzenie" tylko, jeśli użytkownik jest właścicielem wydarzenia
          if (_isUserOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, MaterialPageRoute(
                      builder: (context) => EditEventPage(
                          event: _currentEvent,
                          onSave: (updatedEvent) {
                            setState(() {
                              _currentEvent = updatedEvent;
                            });
                          })
                  ),
                  );
                },
                child: const Text('Edytuj wydarzenie'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _joinOrLeaveEvent();
              },
              child: Text(_isUserJoined ? 'Wypisz się' : 'Zapisz się'),
            ),
          ),
        ],
      ),
    );
  }
}