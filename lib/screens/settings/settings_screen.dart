import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/audio_manager.dart';
import '../../core/reminders/reminders.dart';
import '../../monetization/ad_consent_dialog.dart';
import '../../monetization/prompts/ad_consent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://momahmoud.github.io/Fluxy-Labs/privacy-policy';
  static const String _systemLanguage = 'system';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=${AppConstants.packageId}';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              GameScreenHeader(title: context.l10n.settings),

              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: progress.soundEnabled
                                  ? GameIconKind.soundOn
                                  : GameIconKind.soundOff,
                              label: context.l10n.soundEffects,
                              trailing: Switch(
                                value: progress.soundEnabled,
                                onChanged: (val) {
                                  AudioManager.instance.playClick();
                                  progress.setSoundEnabled(val);
                                },
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                            _SettingsTile(
                              icon: progress.musicEnabled
                                  ? GameIconKind.musicOn
                                  : GameIconKind.musicOff,
                              label: context.l10n.backgroundMusic,
                              trailing: Switch(
                                value: progress.musicEnabled,
                                onChanged: (val) {
                                  AudioManager.instance.playClick();
                                  progress.setMusicEnabled(val);
                                },
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                            _SettingsTile(
                              icon: GameIconKind.haptic,
                              label: context.l10n.hapticFeedback,
                              trailing: Switch(
                                value: progress.vibrationEnabled,
                                onChanged: (val) {
                                  AudioManager.instance.playClick();
                                  progress.setVibrationEnabled(val);
                                },
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                            const _RemindersTile(),
                            const _AdChoicesTile(),
                            _SettingsTile(
                              icon: GameIconKind.theme,
                              label: context.l10n.themeMode,
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<ThemeMode>(
                                  value: progress.themeMode,
                                  dropdownColor: AppColors.surface,
                                  icon: const GameIcon(
                                    kind: GameIconKind.chevronDown,
                                    size: 18,
                                    mirror: false,
                                  ),
                                  style: AppFonts.style(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: ThemeMode.system,
                                      child: Text(context.l10n.themeSystem),
                                    ),
                                    DropdownMenuItem(
                                      value: ThemeMode.light,
                                      child: Text(context.l10n.themeLight),
                                    ),
                                    DropdownMenuItem(
                                      value: ThemeMode.dark,
                                      child: Text(context.l10n.themeDark),
                                    ),
                                  ],
                                  onChanged: (ThemeMode? val) {
                                    if (val != null) {
                                      AudioManager.instance.playClick();
                                      progress.setThemeMode(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            _SettingsTile(
                              icon: GameIconKind.language,
                              label: context.l10n.language,
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      progress.languageCode ?? _systemLanguage,
                                  dropdownColor: AppColors.surface,
                                  icon: const GameIcon(
                                    kind: GameIconKind.chevronDown,
                                    size: 18,
                                    mirror: false,
                                  ),
                                  style: AppFonts.style(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: _systemLanguage,
                                      child: Text(context.l10n.languageSystem),
                                    ),
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Text(context.l10n.languageEnglish),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ar',
                                      child: Text(context.l10n.languageArabic),
                                    ),
                                  ],
                                  onChanged: (String? val) {
                                    if (val == null) return;
                                    AudioManager.instance.playClick();
                                    progress.setLanguageCode(
                                        val == _systemLanguage ? null : val);
                                  },
                                ),
                              ),
                            ),
                            Divider(color: AppColors.surfaceLight, height: 32),
                            if (AppConstants.enableShapePreview)
                              _SettingsTile(
                                icon: GameIconKind.album,
                                label: context.l10n.shapePreview,
                                trailing: const GameIcon(
                                    kind: GameIconKind.chevron, size: 18),
                                onTap: () => Navigator.pushNamed(
                                    context, '/shape_preview'),
                              ),
                            if (AppConstants.enableFirst500Playtest)
                              _SettingsTile(
                                icon: GameIconKind.info,
                                label: 'First-500 playtest (dev)',
                                trailing: const GameIcon(
                                    kind: GameIconKind.chevron, size: 18),
                                onTap: () => Navigator.pushNamed(
                                    context, '/first500_playtest'),
                              ),
                            _SettingsTile(
                              icon: GameIconKind.shield,
                              label: context.l10n.privacyPolicy,
                              trailing: const GameIcon(
                                  kind: GameIconKind.chevron, size: 18),
                              onTap: () => _launchUrl(_privacyPolicyUrl),
                            ),
                            _SettingsTile(
                              icon: GameIconKind.star,
                              label: context.l10n.rateApp,
                              trailing: const GameIcon(
                                  kind: GameIconKind.chevron, size: 18),
                              onTap: () => _launchUrl(_playStoreUrl),
                            ),
                            const Spacer(),
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                final version =
                                    snapshot.data?.version ?? '1.0.4';
                                final buildNumber =
                                    snapshot.data?.buildNumber ?? '5';
                                return Text(
                                  '${AppConstants.appName} v$version+$buildNumber',
                                  style: AppFonts.style(
                                      color: AppColors.textMuted, fontSize: 12),
                                );
                              },
                            ),
                            Text(AppConstants.packageId,
                                style: AppFonts.style(
                                    color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final GameIconKind icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              AudioManager.instance.playClick();
              onTap!();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            FeatureIcon(kind: icon),
            const SizedBox(width: 14),
            Text(label,
                style: AppFonts.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// The daily reminders switch. The setting lives in the reminder service, so
/// it is read from there; turning it on asks the OS for permission.
class _RemindersTile extends StatefulWidget {
  const _RemindersTile();

  @override
  State<_RemindersTile> createState() => _RemindersTileState();
}

class _RemindersTileState extends State<_RemindersTile> {
  bool _on = true;

  @override
  void initState() {
    super.initState();
    reminders.isEnabled().then((on) {
      if (mounted) setState(() => _on = on);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: GameIconKind.dailyReward,
      label: context.l10n.dailyReminders,
      trailing: Switch(
        value: _on,
        onChanged: (value) {
          AudioManager.instance.playClick();
          setState(() => _on = value);
          reminders.setEnabled(value);
        },
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

/// Changes the ad choice. Only players whose region asks the question see it.
class _AdChoicesTile extends StatefulWidget {
  const _AdChoicesTile();

  @override
  State<_AdChoicesTile> createState() => _AdChoicesTileState();
}

class _AdChoicesTileState extends State<_AdChoicesTile> {
  @override
  void initState() {
    super.initState();
    AdConsent.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final consent = AdConsent.instance;
    if (!consent.isRequired) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    return _SettingsTile(
      icon: GameIconKind.noAds,
      label:
          '${AdConsentCopy.settingsTitle(lang)} · '
          '${AdConsentCopy.settingsSubtitle(lang, personalized: consent.choice)}',
      trailing: const GameIcon(
        kind: GameIconKind.chevronDown,
        size: 18,
        mirror: false,
      ),
      onTap: () async {
        await consent.change(() => showAdConsentDialog(context));
        if (mounted) setState(() {});
      },
    );
  }
}
