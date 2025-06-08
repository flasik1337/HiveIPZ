import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // do print() w trybie release
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'local_notification_service.dart';
import '../models/event.dart';

class PollingService {
  int? userId;
  final Duration interval;
  final LocalNotificationService _notifService;
  Timer? _timer;

  // 1) Do wykrywania, które eventy są już „znane”
  Set<String> _knownEventIds = {};
  int knownEventsTotal = 0;

  // 2) Do wykrywania zmian dla danego eventu – mapowanie <eventId, updatedAt>
  final Map<String, DateTime> _eventTimestamps = {};

  PollingService({
    required this.interval,
  }) : _notifService = LocalNotificationService();

  /// Uruchamia cykliczne sprawdzanie co [interval]
  void start() {
    // natychmiastowe pierwsze wywołanie, by ustawić stan początkowy
    _checkAndUpdate(initial: true);
    // a potem co [interval] sekund
    _timer = Timer.periodic(interval, (_) => _checkAndUpdate());
  }

  /// Zatrzymuje polling (np. przy wylogowaniu)
  void stop() {
    _timer?.cancel();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Brak tokena w SharedPreferences");
      }

      final data = await DatabaseHelper.getUserByToken(token);

      userId = data?['id'];
      print('[debug polling] pobrany useerID: $userId');
    } catch (e) {
      print('Błąd podczas pobierania danych użytkownika: $e');
    }
  }

  /// Główna logika sprawdzająca nowe zapisania i edycje.
  Future<void> _checkAndUpdate({bool initial = false}) async {
    final url = Uri.parse('https://vps.jakosinski.pl:5000/users/$userId/events');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> events = data['events'] ?? [];
    final currentIds = events.cast<String>().toSet();

    if (initial) {
      _fetchUserData();
      // Ustawiamy stan początkowy bez powiadomień
      _knownEventIds = currentIds;
      for (var id in currentIds) {
        final event = await _fetchEvent(id);
        if (event != null) {
          _eventTimestamps[id] = event.updatedAt;
          print("DBUG: pieerwotny czas zmiany ventu: ${event.updatedAt}");
        }
      }
      return;
    }

    // 1) Nowe zapisy
    final newIds = currentIds.difference(_knownEventIds);
    for (var id in newIds) {
      final event = await _fetchEvent(id);
      if (event == null) continue;
      await _notifService.showImmediate(
        title: 'Nowy zapis na wydarzenie',
        body: 'Zapisano Cię na: ${event.name}',
        payload: id,
      );
      _eventTimestamps[id] = event.updatedAt;
    }

    // 2) Edycje istniejących
    for (var id in currentIds) {
      final event = await _fetchEvent(id);
      final lastTs = _eventTimestamps[id] ?? DateTime.fromMillisecondsSinceEpoch(0);
      print("DEBUG: ostatnia znana data zmiany: ${lastTs}");
      print("DEBUG: nowa znana data zmiany: ${event?.updatedAt}");
      if (event!.updatedAt.isAfter(lastTs)) {
        await _notifService.showImmediate(
          title: 'Wydarzenie zmienione',
          body: '${event.name}',
          payload: id,
        );
        _eventTimestamps[id] = event.updatedAt;
      }
    }

    // Aktualizujemy zbiór ID
    _knownEventIds = currentIds;
  }

  Future<Event?> _fetchEvent(String id) async {
    try {
      final eventData = await DatabaseHelper.getEvent(id);
      print("DEBUG: ${eventData.toString()}");
      if (eventData != null) {
          final event = Event.fromJson(eventData);
          return event;
      } else return null;
    } catch (e) {
      print('Błąd podczas pobierania wydarzenia: $e');
    }
    return null;
  }
}
