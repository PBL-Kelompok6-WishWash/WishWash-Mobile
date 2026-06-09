import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile/utils/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationListenerManager {
  static final NotificationListenerManager _instance = NotificationListenerManager._internal();
  factory NotificationListenerManager() => _instance;
  
  NotificationListenerManager._internal() {
    _initLocalNotifications();
  }

  WebSocketChannel? _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isConnected = false;
  int? _currentUserId;

  final List<Function(Map<String, dynamic>)> _onNotificationCallbacks = [];

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'wishwash_high_importance_channel_v2', // id
    'WishWash High Importance Notifications', // name
    description: 'This channel is used for important real-time notifications.', // description
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle tap if needed
        },
      );

      // Request permissions and create notification channel for Android
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }
      debugPrint('🔔 Local notifications initialized successfully');
    } catch (e) {
      debugPrint('🔔 Error initializing local notifications: $e');
    }
  }

  void addCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationCallbacks.add(callback);
  }

  void removeCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationCallbacks.remove(callback);
  }

  Future<void> connect(int userId) async {
    if (_isConnected && _currentUserId == userId) return;
    if (_isConnected) {
      disconnect();
    }
    _currentUserId = userId;

    final wsUrl = Constants.baseUrl.replaceFirst('http', 'ws');
    final url = Uri.parse('$wsUrl/notifikasi/ws?id_user=$userId');

    try {
      _channel = WebSocketChannel.connect(url);
      _isConnected = true;
      debugPrint('🔔 Connected to Notification WebSocket for User $userId');
      debugPrint('🔔 [WS Connection] Attempting connection to: $url');

      _channel!.stream.listen(
        (message) {
          _handleIncomingNotification(message);
        },
        onError: (err) {
          debugPrint('🔔 Notification WebSocket error: $err');
          _isConnected = false;
          _reconnect(userId);
        },
        onDone: () {
          debugPrint('🔔 Notification WebSocket closed');
          _isConnected = false;
          _reconnect(userId);
        },
      );
    } catch (e) {
      debugPrint('🔔 Error connecting to Notification WebSocket: $e');
      _isConnected = false;
      _reconnect(userId);
    }
  }

  void _reconnect(int userId) {
    if (_currentUserId != userId) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentUserId == userId && !_isConnected) {
        connect(userId);
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _currentUserId = null;
    debugPrint('🔔 Disconnected from Notification WebSocket');
  }

  Future<void> _showLocalNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'wishwash_high_importance_channel_v2',
        'WishWash High Importance Notifications',
        channelDescription: 'This channel is used for important real-time notifications.',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
      );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
      );
      debugPrint('🔔 Local notification displayed successfully');
    } catch (e) {
      debugPrint('🔔 Error showing local notification: $e');
    }
  }

  Future<void> _handleIncomingNotification(dynamic message) async {
    try {
      final data = jsonDecode(message.toString());
      debugPrint('🔔 New notification received: $data');

      // Check user preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isPushEnabled = prefs.getBool('pref_push_notif') ?? true;

      if (isPushEnabled) {
        final String title = data['judul'] ?? 'Notifikasi Baru';
        final String body = data['pesan'] ?? '';

        // Play sound
        try {
          await _audioPlayer.play(AssetSource('audio/notification.mp3'));
        } catch (e) {
          debugPrint('🔔 Error playing sound asset: $e');
        }

        // Show system notification
        await _showLocalNotification(title, body);
      } else {
        debugPrint('🔔 Push notifications are disabled. Ignoring sound and system alert.');
      }

      // Dispatch callbacks (useful to update in-app notifications/badge count)
      final mapData = Map<String, dynamic>.from(data);
      for (var callback in _onNotificationCallbacks) {
        callback(mapData);
      }
    } catch (e) {
      debugPrint('🔔 Error parsing incoming notification: $e');
    }
  }
}
