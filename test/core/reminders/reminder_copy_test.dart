import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/core/reminders/reminder_copy.dart';
import 'package:arrow_escape/core/reminders/reminder_planner.dart';

void main() {
  const copy = GameReminderCopy(gameAr: 'لعبتي', gameEn: 'My Game');
  final arabic = RegExp(r'[؀-ۿ]');

  test('every kind, language and variant has text', () {
    for (final lang in ['ar', 'en']) {
      for (final kind in ReminderKind.values) {
        for (var variant = 0; variant < 3; variant++) {
          final text = copy.message(kind, lang, variant);
          expect(text.title.trim(), isNotEmpty);
          expect(text.body.trim(), isNotEmpty);
        }
      }
    }
  });

  test('Arabic for Arabic, English for everything else', () {
    expect(arabic.hasMatch(copy.message(ReminderKind.next, 'ar', 0).title), isTrue);
    for (final lang in ['en', 'fr', 'de']) {
      expect(arabic.hasMatch(copy.message(ReminderKind.next, lang, 0).title), isFalse);
    }
  });

  test('names the game', () {
    expect(copy.message(ReminderKind.comeBack, 'en', 0).body, contains('My Game'));
    expect(copy.message(ReminderKind.comeBack, 'ar', 0).body, contains('لعبتي'));
  });

  test('a stray variant still gives text', () {
    expect(copy.message(ReminderKind.next, 'en', 7).title, isNotEmpty);
    expect(copy.message(ReminderKind.next, 'en', -1).title, isNotEmpty);
  });
}
