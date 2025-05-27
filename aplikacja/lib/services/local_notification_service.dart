// lib/services/local_notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class LocalNotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();

  /// (iOS) Prośba o pozwolenia na wyświetlanie powiadomień
  Future<void> requestPermissions() async {
    await _fln
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Natychmiastowe powiadomienie (do testów lub potwierdzeń)
  Future<void> showImmediate({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _fln.show(
      title.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_channel',
          'Natychmiastowe powiadomienia',
          channelDescription: 'Kanał do testów natychmiastowych',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Zaplanowane powiadomienie na określoną datę i godzinę
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _fln.zonedSchedule(
      id.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Zaplanowane powiadomienia',
          channelDescription: 'Kanał lokalnych przypomnień',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Powiadomienie potwierdzające zapis na wydarzenie
  /// oraz zaplanowanie przypomnienia w dniu wydarzenia o godzinie 9:00
  Future<void> notifyOnSignup({
    required String eventId,
    required String eventName,
    required DateTime eventStart,
  }) async {
    // Pokazanie natychmiastowego potwierdzenia zapisu
    await showImmediate(
      title: 'Zapisany na wydarzenie',
      body: 'Zapisano Cię na: $eventName',
      payload: eventId,
    );

    // Zaplanowanie przypomnienia w dniu wydarzenia o godzinie 9:00
    final remindAt = DateTime(
      eventStart.year,
      eventStart.month,
      eventStart.day,
      9,
      0,
      0,
    );
    if (remindAt.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 'reminder_$eventId',
        title: 'Dziś wydarzenie: $eventName',
        body: 'Wydarzenie “$eventName” odbywa się dzisiaj.',
        scheduledDate: remindAt,
      );
    }
  }

  static Future<void> initialize(FlutterLocalNotificationsPlugin fln) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await fln.initialize(
        initializationSettings, onDidReceiveNotificationResponse: (resp) {
      // obsługa tapnięcia na powiadomienie
    });

    if (Platform.isAndroid) {
      const channels = <AndroidNotificationChannel>[
        AndroidNotificationChannel('immediate_channel', 'Kanał natychmiastiowy',
          description: 'Kanał powiadomień natychmiastowych',
          importance: Importance.high,),
        AndroidNotificationChannel('scheduled_channel', 'Kanał zaplanowany',
          description: 'Kanał powiadomień zaplanowanych na daną datę i godzinę',
          importance: Importance.high,),
      ];

      final androidImpl = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      for (var channel in channels) {
        await androidImpl?.createNotificationChannel(channel);
      }
    }
  }


  Future<void> requestPermisions() async {
    if (Platform.isAndroid) {
      await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }
}
