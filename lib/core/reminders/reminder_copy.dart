import 'reminder_planner.dart';
import 'reminder_service.dart';

/// The reminder wording shared by the games: warm, specific, never guilt or
/// false urgency. Each game supplies its own name; the language is Arabic
/// when the player's language is Arabic, English otherwise.
class GameReminderCopy implements ReminderCopy {
  const GameReminderCopy({required this.gameAr, required this.gameEn});

  final String gameAr;
  final String gameEn;

  @override
  String channelName(String languageCode) =>
      languageCode == 'ar' ? 'التذكيرات' : 'Reminders';

  @override
  String channelDescription(String languageCode) => languageCode == 'ar'
      ? 'تذكيرات خفيفة للعب'
      : 'Gentle reminders to play';

  @override
  ReminderText message(ReminderKind kind, String languageCode, int variant) {
    final ar = languageCode == 'ar';
    final game = ar ? gameAr : gameEn;
    final texts = ar ? _ar(game, kind) : _en(game, kind);
    return texts[variant.abs() % texts.length];
  }

  List<ReminderText> _en(String game, ReminderKind kind) => switch (kind) {
    ReminderKind.next => [
      (
        title: 'Your daily gift is ready 🎁',
        body: 'Come claim your free coins in $game.',
      ),
      (
        title: 'Can you beat your best? 🧩',
        body: 'A new level is waiting in $game.',
      ),
      (
        title: 'Time for a quick game ⏱️',
        body: 'Two minutes is enough for a new challenge in $game.',
      ),
    ],
    ReminderKind.comeBack => [
      (
        title: 'We miss you 💙',
        body: 'New levels and free coins are waiting in $game.',
      ),
      (
        title: 'Your progress is saved',
        body: 'Pick up $game right where you left off.',
      ),
      (
        title: 'A new challenge awaits',
        body: 'Come back to $game and test your skills.',
      ),
    ],
    ReminderKind.lastCall => [
      (
        title: 'Come back anytime 👋',
        body: 'Your gift and progress are waiting in $game.',
      ),
      (
        title: 'New levels since your last visit',
        body: 'Take a look at what you missed in $game.',
      ),
      (
        title: '$game is waiting',
        body: 'No rush — play whenever you like.',
      ),
    ],
  };

  List<ReminderText> _ar(String game, ReminderKind kind) => switch (kind) {
    ReminderKind.next => [
      (
        title: 'هديتك اليومية جاهزة 🎁',
        body: 'ادخل واستلم عملاتك المجانية في $game.',
      ),
      (
        title: 'هل تكسر رقمك القياسي؟ 🧩',
        body: 'مستوى جديد بانتظارك في $game.',
      ),
      (
        title: 'وقت لعبة سريعة ⏱️',
        body: 'دقيقتان تكفي لتحدٍّ جديد في $game.',
      ),
    ],
    ReminderKind.comeBack => [
      (
        title: 'اشتقنا لك 💙',
        body: 'مستويات جديدة وعملات مجانية بانتظارك في $game.',
      ),
      (
        title: 'تقدّمك محفوظ',
        body: 'كمّل $game من حيث توقفت.',
      ),
      (
        title: 'تحدٍّ جديد بانتظارك',
        body: 'عُد إلى $game واختبر مهارتك.',
      ),
    ],
    ReminderKind.lastCall => [
      (
        title: 'عُد متى شئت 👋',
        body: 'هديتك وتقدّمك بانتظارك في $game.',
      ),
      (
        title: 'مستويات جديدة منذ آخر زيارة',
        body: 'ألقِ نظرة على ما فاتك في $game.',
      ),
      (
        title: '$game بانتظارك',
        body: 'لا استعجال — العب حين تشاء.',
      ),
    ],
  };
}
