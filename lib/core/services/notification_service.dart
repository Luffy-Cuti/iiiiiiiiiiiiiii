import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
  }

  Future<void> showUploadProgress(int progress) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'upload_progress',
        'Upload Progress',
        channelDescription: 'Shows current upload percentage',
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      9001,
      'Uploading video',
      '$progress% complete',
      details,
    );
  }
}