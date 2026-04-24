import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _uploadNotificationId = 9001;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      _uploadNotificationId,
      'Đang upload video... $progress%',
      'Tiến trình đăng video đang chạy nền.',
      details,
    );
  }

  Future<void> showUploadSuccess() async {
    await _plugin.show(
      _uploadNotificationId,
      '✅ Video đã được đăng thành công!',
      'Nhấn để xem video mới đăng.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_result',
          'Upload Result',
          channelDescription: 'Shows upload result',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showUploadFailure() async {
    await _plugin.show(
      _uploadNotificationId,
      '❌ Upload thất bại. Nhấn để thử lại',
      'Vui lòng kiểm tra lại thông tin video.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_result',
          'Upload Result',
          channelDescription: 'Shows upload result',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showUploadCancelled() async {
    await _plugin.cancel(_uploadNotificationId);
  }
}
