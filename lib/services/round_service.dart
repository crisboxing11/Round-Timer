import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android foreground service that keeps the timer process alive (and the
/// notification current) while the screen is off or the app is backgrounded.
/// The engine itself stays in the main isolate — the service exists so the
/// OS never freezes us mid-round. No-op on every other platform: iOS covers
/// this with the background-audio session instead.
class RoundService {
  static bool get _supported => !kIsWeb && Platform.isAndroid;
  static bool _running = false;
  static String _lastText = '';

  static Future<void> start({
    required String title,
    required String text,
  }) async {
    if (!_supported || _running) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'round_timer_session',
        channelName: 'Active round timer',
        channelDescription: 'Shows the running round and remaining time.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowAutoRestart: false,
        stopWithTask: true,
      ),
    );
    // Android 13+ needs POST_NOTIFICATIONS; a denial hides the notification
    // but must never block the timer itself.
    try {
      final status =
          await FlutterForegroundTask.checkNotificationPermission();
      if (status != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (e) {
      debugPrint('RoundService: notification permission check failed: $e');
    }
    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.mediaPlayback],
      notificationTitle: title,
      notificationText: text,
    );
    _running = result is ServiceRequestSuccess;
    _lastText = text;
    if (!_running) debugPrint('RoundService: start failed: $result');
  }

  /// Cheap to call every tick — only touches the platform when the visible
  /// text actually changed (i.e. once per second).
  static Future<void> update({
    required String title,
    required String text,
  }) async {
    if (!_supported || !_running) return;
    final key = '$title|$text';
    if (key == _lastText) return;
    _lastText = key;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  static Future<void> stop() async {
    if (!_supported || !_running) return;
    _running = false;
    _lastText = '';
    await FlutterForegroundTask.stopService();
  }
}
