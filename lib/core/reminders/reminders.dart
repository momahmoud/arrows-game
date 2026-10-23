import 'reminder_copy.dart';
import 'reminder_service.dart';

/// The language reminders are written in; kept in step with the game's.
String reminderLanguageCode = 'en';

/// The app's retention reminders.
final ReminderService reminders = ReminderService(
  copy: const GameReminderCopy(gameAr: 'هروب الأسهم', gameEn: 'Arrow Escape'),
  languageCode: () => reminderLanguageCode,
  androidIcon: '@mipmap/launcher_icon',
);
