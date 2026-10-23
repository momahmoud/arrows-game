import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_planner.dart';

/// The wording of a reminder.
typedef ReminderText = ({String title, String body});

/// What a game says in each reminder, in the player's language.
abstract class ReminderCopy {
  String channelName(String languageCode);
  String channelDescription(String languageCode);
  ReminderText message(ReminderKind kind, String languageCode, int variant);
}

/// Local retention reminders: a short ladder after the player leaves, at
/// their usual play time, cleared when they come back.
///
/// Asking for permission is left to the game, at a good moment, through
/// [requestPermissionOnce]; nothing is scheduled without it or without the
/// player's switch being on.
class ReminderService {
  ReminderService({
    required this.copy,
    required this.languageCode,
    this.androidIcon = '@mipmap/ic_launcher',
    this.channelId = 'reminders',
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _clock = clock ?? DateTime.now;

  final ReminderCopy copy;

  /// The game's current language, read when planning.
  final String Function() languageCode;
  final String androidIcon;
  final String channelId;

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;

  static const _enabledKey = 'reminders_enabled';
  static const _askedKey = 'reminders_permission_asked';
  static const _hourKey = 'reminders_usual_hour';

  bool _ready = false;
  AppLifecycleListener? _lifecycle;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<void> initialize() async {
    if (!isSupported || _ready) return;
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (error) {
      debugPrint('Reminders: init failed: $error');
    }
  }

  /// Plans reminders whenever the app goes to the background, and clears
  /// them whenever it comes back. Call once at start-up.
  void watchLifecycle() {
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(onForeground()),
      onPause: () => unawaited(onBackground()),
    );
  }

  /// The player's switch. On unless they turned it off.
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Turning it off cancels everything pending; turning it on asks for the
  /// OS permission (the player just asked for reminders, so it is a good
  /// moment) and plans on the next time they leave.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!_ready) return;
    if (!enabled) {
      await _plugin.cancelAllPendingNotifications();
      return;
    }
    await prefs.setBool(_askedKey, true);
    await _requestPermission();
  }

  /// Asks the OS for permission the first time only, at a moment of value
  /// (after the player's first win), not at launch.
  Future<void> requestPermissionOnce() async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) return;
    await prefs.setBool(_askedKey, true);
    if (!await isEnabled()) return;
    await _requestPermission();
  }

  /// Whether the OS lets this app show notifications.
  Future<bool> osAllows() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      return options != null &&
          (options.isEnabled || options.isProvisionalEnabled) &&
          options.isAlertEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (error) {
      debugPrint('Reminders: permission failed: $error');
      return false;
    }
  }

  /// The player is back: remember when they play, and drop every pending
  /// reminder, since they are no longer needed.
  Future<void> onForeground() async {
    if (!_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hourKey, _clock().hour);
      await _plugin.cancelAllPendingNotifications();
    } catch (error) {
      debugPrint('Reminders: cancel failed: $error');
    }
  }

  /// The player is leaving: plan the ladder, if they want it and the OS
  /// allows it.
  Future<void> onBackground() async {
    if (!_ready) return;
    try {
      if (!await isEnabled() || !await osAllows()) return;
      final prefs = await SharedPreferences.getInstance();
      final plans = ReminderPlanner.plan(
        now: _clock(),
        usualHour: prefs.getInt(_hourKey),
      );
      final language = languageCode();
      await _plugin.cancelAllPendingNotifications();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          copy.channelName(language),
          channelDescription: copy.channelDescription(language),
          // A reminder, not an alert: no heads-up banner.
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      for (final plan in plans) {
        final text = copy.message(plan.kind, language, plan.variant);
        await _plugin.zonedSchedule(
          id: plan.id,
          title: text.title,
          body: text.body,
          scheduledDate: tz.TZDateTime.from(plan.when, tz.local),
          notificationDetails: details,
          // Inexact: no special alarm permission, and a reminder doesn't
          // need to be on the minute.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (error) {
      debugPrint('Reminders: scheduling failed: $error');
    }
  }
}
