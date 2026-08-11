import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _channel;

  NotificationService(this._ref);

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (details.payload != null) {
          // Navigation logic can be handled here or via a listener
        }
      },
    );
  }

  void subscribeToNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _channel = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            _showLocalNotification(
              id: newRecord['id'].hashCode,
              title: newRecord['title'],
              body: newRecord['body'],
              payload: newRecord['report_id'],
            );
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _channel?.unsubscribe();
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ecopin_notifications',
      'EcoPin Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
