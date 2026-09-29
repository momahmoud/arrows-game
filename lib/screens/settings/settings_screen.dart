import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/audio_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/l10n.dart';

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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(context.l10n.settings,
                        style: AppFonts.style(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),

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
                              icon: Icons.volume_up_outlined,
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
                              icon: Icons.music_note_outlined,
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
                              icon: Icons.vibration_rounded,
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
                            _SettingsTile(
                              icon: Icons.brightness_medium_outlined,
                              label: context.l10n.themeMode,
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<ThemeMode>(
                                  value: progress.themeMode,
                                  dropdownColor: AppColors.surface,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: AppColors.textPrimary),
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
                              icon: Icons.language_rounded,
                              label: context.l10n.language,
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      progress.languageCode ?? _systemLanguage,
                                  dropdownColor: AppColors.surface,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: AppColors.textPrimary),
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
                                icon: Icons.category_outlined,
                                label: context.l10n.shapePreview,
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary),
                                onTap: () => Navigator.pushNamed(
                                    context, '/shape_preview'),
                              ),
                            _SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              label: context.l10n.privacyPolicy,
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary),
                              onTap: () => _launchUrl(_privacyPolicyUrl),
                            ),
                            _SettingsTile(
                              icon: Icons.star_outline_rounded,
                              label: context.l10n.rateApp,
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary),
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
  final IconData icon;
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
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
