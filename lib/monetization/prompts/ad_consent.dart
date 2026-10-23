import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// Where the law makes us ask before using a player's data for ads: the EEA,
/// the UK and Switzerland (GDPR and its equivalents). Elsewhere nothing is
/// asked and ads simply run.
///
/// The region comes from the device: the regions of its languages, and its
/// time zone. When either says "Europe" the question is asked, so a player
/// is more likely to be asked than missed (a traveller, say, may be asked
/// once).
class ConsentRegion {
  const ConsentRegion._();

  static const Set<String> _countries = {
    // EEA
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK',
    'SI', 'ES', 'SE', 'IS', 'LI', 'NO',
    // UK and Switzerland
    'GB', 'CH',
  };

  static const Set<String> _zones = {
    'Europe/Vienna',
    'Europe/Brussels',
    'Europe/Sofia',
    'Europe/Zagreb',
    'Asia/Nicosia',
    'Europe/Nicosia',
    'Europe/Prague',
    'Europe/Copenhagen',
    'Europe/Tallinn',
    'Europe/Helsinki',
    'Europe/Mariehamn',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Busingen',
    'Europe/Athens',
    'Europe/Budapest',
    'Europe/Dublin',
    'Europe/Rome',
    'Europe/Riga',
    'Europe/Vilnius',
    'Europe/Luxembourg',
    'Europe/Malta',
    'Europe/Amsterdam',
    'Europe/Warsaw',
    'Europe/Lisbon',
    'Atlantic/Madeira',
    'Atlantic/Azores',
    'Europe/Bucharest',
    'Europe/Bratislava',
    'Europe/Ljubljana',
    'Europe/Madrid',
    'Atlantic/Canary',
    'Africa/Ceuta',
    'Europe/Stockholm',
    'Europe/Oslo',
    'Arctic/Longyearbyen',
    'Atlantic/Reykjavik',
    'Europe/Vaduz',
    'Europe/London',
    'Europe/Jersey',
    'Europe/Guernsey',
    'Europe/Isle_of_Man',
    'Europe/Zurich',
  };

  /// Whether a device with these language regions and this time zone is in
  /// a region that needs the question.
  static bool requiresConsent({
    Iterable<String?> countryCodes = const [],
    String? timeZone,
  }) {
    for (final code in countryCodes) {
      if (code != null && _countries.contains(code.toUpperCase())) return true;
    }
    return timeZone != null && _zones.contains(timeZone);
  }

  /// Reads the device. Any failure counts as "not required" for the time
  /// zone half, so a broken lookup can't leave a game stuck asking.
  static Future<bool> detect() async {
    final countries = PlatformDispatcher.instance.locales.map(
      (l) => l.countryCode,
    );
    String? zone;
    try {
      zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {}
    return requiresConsent(countryCodes: countries, timeZone: zone);
  }
}

/// Where the player's answer is kept.
abstract class ConsentStore {
  Future<bool?> load();
  Future<void> save(bool personalized);
}

class SharedPreferencesConsentStore implements ConsentStore {
  const SharedPreferencesConsentStore();

  static const _key = 'ad_consent_personalized';

  @override
  Future<bool?> load() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(bool personalized) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, personalized);
    } catch (_) {
      // The answer still holds for this run.
    }
  }
}

/// The player's ad choice. Asked only where [ConsentRegion] says it must
/// be; ads wait for the answer there and start at once everywhere else.
class AdConsent {
  AdConsent({
    ConsentStore store = const SharedPreferencesConsentStore(),
    Future<bool> Function()? detectRegion,
    Future<void> Function(bool personalized)? apply,
  })  : _store = store,
        _detectRegion = detectRegion ?? ConsentRegion.detect,
        _apply = apply ?? applyToLevelPlay;

  /// The app-wide instance.
  static final AdConsent instance = AdConsent();

  final ConsentStore _store;
  final Future<bool> Function() _detectRegion;
  final Future<void> Function(bool personalized) _apply;

  bool _required = false;
  bool? _choice;
  bool _asking = false;
  Completer<void>? _answered;
  late final Future<void> _loaded = _load();

  Future<void> _load() async {
    _choice = await _store.load();
    try {
      _required = await _detectRegion();
    } catch (_) {
      _required = false;
    }
  }

  /// Reads the saved answer and the region. Safe to call again.
  Future<void> load() => _loaded;

  /// Whether this player's region needs the question. Valid after [load].
  bool get isRequired => _required;

  /// The saved answer: true for personalized ads, null if never asked.
  bool? get choice => _choice;

  bool get needsAnswer => _required && _choice == null;

  /// What ad start-up waits for: the player's answer where one is needed,
  /// and nothing at all elsewhere. Null means "no choice was made", for which
  /// no consent setting is passed on.
  Future<bool?> get decision async {
    await load();
    if (!needsAnswer) return _choice;
    final waiter = _answered ??= Completer<void>();
    await waiter.future;
    return _choice;
  }

  /// Records an answer and passes it to the ad network.
  Future<void> answer(bool personalized) async {
    await load();
    _choice = personalized;
    await _store.save(personalized);
    try {
      await _apply(personalized);
    } catch (error) {
      debugPrint('Ad consent: could not apply the choice: $error');
    }
    final waiter = _answered;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
  }

  /// Asks the question through [show] when it is needed. [show] returns the
  /// player's choice, or null if the question went away unanswered, in which
  /// case it is asked again next time. Only one question at a time.
  Future<void> askIfNeeded(Future<bool?> Function() show) async {
    await load();
    if (!needsAnswer || _asking) return;
    _asking = true;
    try {
      final personalized = await show();
      if (personalized != null) await answer(personalized);
    } finally {
      _asking = false;
    }
  }

  /// Lets the player change their mind, e.g. from Settings.
  Future<void> change(Future<bool?> Function() show) async {
    await load();
    if (_asking) return;
    _asking = true;
    try {
      final personalized = await show();
      if (personalized != null) await answer(personalized);
    } finally {
      _asking = false;
    }
  }

  /// Passes the choice to LevelPlay. It must be set before LevelPlay starts,
  /// and may be changed afterwards.
  static Future<void> applyToLevelPlay(bool personalized) async {
    await LevelPlayPrivacySettings.setGDPRConsent(personalized);
    // CCPA's flag means "opted out of the sale of personal data".
    await LevelPlayPrivacySettings.setCCPA(!personalized);
    // The games are not directed at children.
    await LevelPlayPrivacySettings.setCOPPA(false);
  }
}

/// The question's wording, in Arabic or English.
class AdConsentCopy {
  const AdConsentCopy._();

  static bool _ar(String languageCode) => languageCode == 'ar';

  static String title(String lang) =>
      _ar(lang) ? 'خيارات الإعلانات' : 'Your ad choices';

  static String body(String lang, String game) => _ar(lang)
      ? 'لعبة $game مجانية بفضل الإعلانات. هل تسمح لشركائنا الإعلانيين '
          'باستخدام بيانات هذا الجهاز لعرض إعلانات تناسبك أكثر؟ يمكنك '
          'تغيير ذلك في أي وقت من الإعدادات.'
      : '$game is free thanks to ads. May our ad partners use data from this '
          'device to show ads that suit you better? You can change this '
          'any time in Settings.';

  static String allow(String lang) =>
      _ar(lang) ? 'السماح بإعلانات مخصصة' : 'Allow personalized ads';

  static String decline(String lang) =>
      _ar(lang) ? 'إعلانات غير مخصصة' : 'Show non-personalized ads';

  static String settingsTitle(String lang) =>
      _ar(lang) ? 'خيارات الإعلانات' : 'Ad choices';

  static String settingsSubtitle(String lang, {required bool? personalized}) {
    final on = personalized ?? false;
    if (_ar(lang)) return on ? 'إعلانات مخصصة' : 'إعلانات غير مخصصة';
    return on ? 'Personalized ads' : 'Non-personalized ads';
  }
}

/// Asks the ad question on the screen it is placed on, when it is needed.
/// Put it on the first screen the player looks at, not over a splash: it
/// waits until its screen is the one in front.
class AdConsentTrigger extends StatefulWidget {
  const AdConsentTrigger({
    super.key,
    required this.show,
    required this.child,
    this.consent,
  });

  /// Shows the question and returns true (personalized), false, or null if
  /// it went away unanswered.
  final Future<bool?> Function(BuildContext context) show;
  final Widget child;

  /// For tests; the app-wide [AdConsent.instance] otherwise.
  final AdConsent? consent;

  @override
  State<AdConsentTrigger> createState() => _AdConsentTriggerState();
}

class _AdConsentTriggerState extends State<AdConsentTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  /// Waits until this screen is in front: a splash, a welcome screen or
  /// another screen may be above it for as long as it likes. Gives up only
  /// if this screen goes away.
  Future<bool> _inFront() async {
    while (mounted) {
      if (ModalRoute.of(context)?.isCurrent ?? true) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  Future<void> _ask() async {
    final consent = widget.consent ?? AdConsent.instance;
    await consent.load();
    if (!consent.needsAnswer || !mounted) return;
    if (!await _inFront() || !mounted) return;
    await consent.askIfNeeded(() => widget.show(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
