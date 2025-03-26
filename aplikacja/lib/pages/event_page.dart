import 'package:flutter/material.dart';
import '../models/event.dart';
import '../styles/gradients.dart';
import '../pages/edit_event_page.dart';
import '../database/database_helper.dart';
import '../styles/text_styles.dart';
import '../widgets/payment_dialog.dart';

/// Strona realizująca widok szczegółowy wydarzenia
class EventPage extends StatefulWidget {
  final Event event;
  final Function(Event) onUpdate;

  const EventPage({super.key, required this.event, required this.onUpdate});

  @override
  _EventPageState createState() => _EventPageState();
}

Widget _buildActionButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Color(0xFFFFC300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _EventPageState extends State<EventPage> {
  late Event currentEvent; // aktualne wydarzenie
  bool isUserJoined = false; // Czy użytkownik jest zapisany na wydarzenie
  bool isUserOwner = false; // Czy użytkownik jest właścicielem wydarzenia?
  String? userId; // Przechowywanie userId

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
    _fetchEvent();
    _initializeUser(); // Inicjalizacja użytkownika
  }



  Future<void> _initializeUser() async {
    try {
      userId = await DatabaseHelper.getUserIdFromToken();
      _checkUserJoinedStatus();
      _checkIfUserIsOwner();
    } catch (e) {
      print('Błąd podczas inicjalizacji użytkownika: $e');
    }
  }

  Future<void> _fetchEvent() async {
    try {
      final eventData = await DatabaseHelper.getEvent(widget.event.id);
      if (eventData != null) {
        setState(() {
          currentEvent = Event.fromJson(eventData);
        });
      }
    } catch (e) {
      print('Błąd podczas pobierania wydarzenia: $e');
    }
  }

  void _showParticipantsModal(BuildContext context) async {
    List<String> participants = await DatabaseHelper.getEventParticipants(currentEvent.id);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lista uczestników',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: participants.isEmpty
                    ? const Center(child: Text('Brak uczestników'))
                    : ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(participants[index]),
                      trailing: isUserOwner
                          ? IconButton(
                        icon: Icon(Icons.block, color: Colors.red),
                        onPressed: () async {
                          try {
                            await DatabaseHelper.banUser(
                                currentEvent.id, participants[index]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Użytkownik zbanowany')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Błąd: $e')),
                            );
                          }
                        },
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _checkIfUserIsOwner() {
    if (userId != null) {
      setState(() {
        isUserOwner = currentEvent.userId == int.tryParse(userId!);
      });
    }
  }

  Future<void> _checkUserJoinedStatus() async {
    if (userId != null) {
      try {
        final isJoined = await DatabaseHelper.isUserJoinedEvent(
            currentEvent.id, userId!);

        setState(() {
          isUserJoined = isJoined;
        });
      } catch (e) {
        print('Błąd podczas sprawdzania statusu użytkownika: $e');
      }
    }
  }

  Future<void> _joinOrLeaveEvent() async {
    try {
      if (isUserJoined) {
        // Logika wypisywania
        await DatabaseHelper.leaveEvent(currentEvent.id);
        setState(() {
          isUserJoined = false;
          currentEvent = currentEvent.copyWith(
            registeredParticipants: currentEvent.registeredParticipants - 1,
          );
        });
      } else {
        // Sprawdź limit uczestników
        if (currentEvent.maxParticipants != -1 &&
            currentEvent.registeredParticipants >= currentEvent.maxParticipants) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wydarzenie jest już pełne!')),
          );
          return;
        }

        // Obsługa płatności dla wydarzeń płatnych
        if (currentEvent.cena > 0) {
          final paymentConfirmed = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PaymentBottomSheet(),
          );

          if (paymentConfirmed != true) return;
        }

        // Zapisz użytkownika na wydarzenie
        await DatabaseHelper.joinEvent(currentEvent.id);
        setState(() {
          isUserJoined = true;
          currentEvent = currentEvent.copyWith(
            registeredParticipants: currentEvent.registeredParticipants + 1,
          );
        });
      }
    } catch (e) {
      print('Błąd podczas zapisu/wypisu: $e');
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
                currentEvent.imagePath,
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
                  currentEvent.name,
                  textAlign: TextAlign.center,
                  style: HiveTextStyles.title,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${currentEvent.location}  |  ${currentEvent.type}\n${currentEvent.startDate.day}.${currentEvent.startDate.month}.${currentEvent.startDate.year}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              currentEvent.cena > 0
                  ? 'Cena wejścia: ${currentEvent.cena} zł'
                  : 'Wejście darmowe',
              style: HiveTextStyles.regular,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              currentEvent.description,
              style: HiveTextStyles.regular,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentEvent.maxParticipants != -1
                  ? '${currentEvent.registeredParticipants} / ${currentEvent
                  .maxParticipants}'
                  : 'Wydarzenie otwarte, ${currentEvent.registeredParticipants} uczestników',
              style: HiveTextStyles.regular,
            ),
          ),

          // Wyświetl przycisk "Edytuj wydarzenie" tylko, jeśli użytkownik jest właścicielem wydarzenia
          if (isUserOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionButton('Edytuj wydarzenie', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventPage(
                          event: currentEvent,
                          onSave: (updatedEvent) {
                            setState(() {
                              currentEvent = updatedEvent;
                            });
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildActionButton(
                      currentEvent.isPromoted ? 'Usuń promocję' : 'Promuj wydarzenie',
                      () async {
                    try {
                      final updated = currentEvent.copyWith(isPromoted: !currentEvent.isPromoted);
                      await DatabaseHelper.updateEvent(
                        currentEvent.id,
                        {
                          'name': currentEvent.name,
                          'location': currentEvent.location,
                          'description': currentEvent.description,
                          'type': currentEvent.type,
                          'start_date': currentEvent.startDate.toIso8601String(),
                          'max_participants': currentEvent.maxParticipants,
                          'registered_participants': currentEvent.registeredParticipants,
                          'image': currentEvent.imagePath,
                          'cena': currentEvent.cena,
                          'is_promoted': updated.isPromoted,
                        },
                      );
                      setState(() {
                        currentEvent = updated;
                      });
                      widget.onUpdate(updated);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd: $e')),
                      );
                    }
                  }),
                  const SizedBox(height: 12),
                  _buildActionButton('Zobacz uczestników', () {
                    _showParticipantsModal(context);
                  }),
                ],
              ),
            ),
          // Wyświetl przycisk "Zapisz się / Wypisz się" tylko, jeśli użytkownik nie jest właścicielem wydarzenia
          if (!isUserOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  _joinOrLeaveEvent();
                },
                child: Text(isUserJoined ? 'Wypisz się' : 'Zapisz się'),
              ),
            ),
             
        ],
      ),
    );
  }
}