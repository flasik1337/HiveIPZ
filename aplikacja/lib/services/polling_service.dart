import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'local_notification_service.dart';
import '../main.dart';

class PollingService {
  final String userId;
  final LocalNotificationService _notifService;
  final Duration interval;
  Timer? _timer;
  Set<String> _knownEventIds = {};

  PollingService({
    required this.userId,
    required this.interval,
    required FlutterLocalNotificationsPlugin flnPlugin,
  }) : _notifService = LocalNotificationService();

  void start() {
    // natychmiast pobierz i zapamiętaj stan początkowy
    _checkAndUpdate(initial: true);
    // uruchom polling
    _timer = Timer.periodic(interval, (_) => _checkAndUpdate());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _checkAndUpdate({bool initial = false}) async {
    final url = Uri.parse('https://vps.jakosinski.pl:5000/users/$userId/events');
    final resp = await http.get(url /*, headers: {...} */);
    if (resp.statusCode != 200) return;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> events = data['events'] ?? [];

    final current = events.cast<String>().toSet();
    if (initial) {
      // przy pierwszym wywołaniu tylko zapamiętujemy, bez powiadomień
      _knownEventIds = current;
      return;
    }

    // znajdź nowo dodane eventy
    final newEvents = current.difference(_knownEventIds);

    for (final eventId in newEvents) {
      // możesz pobrać dodatkowe info o evencie, np. nazwę, z innego endpointu
      final eventName = await _fetchEventName(eventId);

      // pokaż powiadomienie
      await _notifService.showImmediate(
        title: 'Nowy zapis na wydarzenie',
        body: 'Zapisano Cię na: $eventName',
        payload: eventId,
      );
    }

    // zaktualizuj zbiór
    _knownEventIds = current;
  }

  Future<String> _fetchEventName(String eventId) async {
    final url = Uri.parse('https://vps.jakosinski.pl:5000/events/$eventId');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return 'Wydarzenie $eventId';
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['name'] as String? ?? 'Wydarzenie $eventId';
  }
}
