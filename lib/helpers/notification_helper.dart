import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Pake named parameter
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle ketika user tap notifikasi
      },
    );
  }

  static Future<void> showNewOrderNotification({
    required String customerName,
    required String serviceName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Pesanan Baru',
      channelDescription: 'Notifikasi pesanan masuk dari pelanggan',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    // Pake named parameter semua
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔔 Pesanan Baru!',
      body: '$customerName - $serviceName',
      notificationDetails: details,
    );
  }
}
