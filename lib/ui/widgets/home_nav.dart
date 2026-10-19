import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/audio_manager.dart';
import '../../core/constants.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'game_badges.dart';
import 'game_button.dart';
import 'gameplay_hud.dart';
import 'icon_kit.dart';

/// Settings, the game name, and the coin balance.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.coins,
    required this.onSettings,
    required this.onCoins,
  });

  final int coins;
  final VoidCallback onSettings;
  final VoidCallback onCoins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: CoinBalancePill(amount: coins, onAdd: onCoins),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppConstants.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GameTypography.section(GameColors.text),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GameIconButton(
                kind: GameIconKind.settings,
                tooltip: context.l10n.settings,
                onPressed: onSettings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The next puzzle, without a dashboard card around it.
class CurrentLevelSection extends StatelessWidget {
  const CurrentLevelSection({
    super.key,
    required this.level,
    required this.difficulty,
    required this.levelType,
    required this.finished,
  });

  final int level;
  final String difficulty;
  final LevelType levelType;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final special = levelType == LevelType.god || levelType == LevelType.boss;
    return Column(
      children: [
        if (levelType == LevelType.god)
          const GodBadge(size: 22)
        else if (levelType == LevelType.boss)
          const BossBadge(size: 22),
        if (special) const SizedBox(height: 6),
        _SoftPulse(
          child: Text(
            finished
                ? context.l10n.finishedGameTitle
                : context.l10n.levelNumber(level),
            textAlign: TextAlign.center,
            style: finished
                ? GameTypography.section(GameColors.text)
                : GameTypography.level(AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          difficulty,
          textAlign: TextAlign.center,
          style: GameTypography.caption(GameColors.textMuted),
        ),
      ],
    );
  }
}

class _SoftPulse extends StatefulWidget {
  const _SoftPulse({required this.child});

  final Widget child;

  @override
  State<_SoftPulse> createState() => _SoftPulseState();
}

class _SoftPulseState extends State<_SoftPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: GameMotion.levelPulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GameMotion.reduce(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + 0.03 * _pulse.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PlayNowButton extends StatelessWidget {
  const PlayNowButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      icon: loading ? null : GameIconKind.play,
      leading: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : null,
      onPressed: onPressed,
    );
  }
}

/// Five nearby levels. The full grid lives on Level Select.
class LevelProgressPreview extends StatelessWidget {
  const LevelProgressPreview({
    super.key,
    required this.currentLevel,
    required this.totalLevels,
    required this.isUnlocked,
    required this.starsFor,
    required this.onSelect,
    required this.onLocked,
    required this.onViewAll,
  });

  final int currentLevel;
  final int totalLevels;
  final bool Function(int level) isUnlocked;
  final int Function(int level) starsFor;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onLocked;
  final VoidCallback onViewAll;

  List<int> get _window {
    final current = currentLevel.clamp(1, totalLevels);
    var start = current - 2;
    var end = current + 2;
    if (start < 1) {
      end += 1 - start;
      start = 1;
    }
    if (end > totalLevels) {
      start -= end - totalLevels;
      end = totalLevels;
    }
    start = start.clamp(1, totalLevels);
    return [for (var i = start; i <= end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: _homeCard(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Column(
            children: [
              Row(
                children: [
                  for (final level in _window)
                    Expanded(
                      child: _ProgressNode(
                        level: level,
                        current: level == currentLevel,
                        unlocked: isUnlocked(level),
                        stars: starsFor(level),
                        onTap: () {
                          if (isUnlocked(level)) {
                            onSelect(level);
                          } else {
                            onLocked(level);
                          }
                        },
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.viewAllLevels,
                      style: GameTypography.caption(AppColors.primary),
                    ),
                    const SizedBox(width: 2),
                    const GameIcon(kind: GameIconKind.chevron, size: 14),
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

class _ProgressNode extends StatelessWidget {
  const _ProgressNode({
    required this.level,
    required this.current,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final bool current;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0 && !current;
    final size = current ? 48.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: GameMotion.tap,
            curve: Curves.easeOut,
            width: size,
            height: size + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current
                  ? AppColors.primary
                  : unlocked
                      ? AppColors.surface
                      : AppColors.elevated,
              borderRadius: BorderRadius.circular(GameRadius.sm),
              border: Border.all(
                color: current
                    ? AppColors.primary
                    : completed
                        ? AppColors.accentGreen.withValues(alpha: 0.65)
                        : unlocked
                            ? AppColors.surfaceLight
                            : AppColors.surfaceLight.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: current
                      ? AppColors.primary.withValues(alpha: 0.22)
                      : Colors.black.withValues(
                          alpha: AppColors.isDark ? 0.22 : 0.05,
                        ),
                  blurRadius: current ? 8 : 6,
                  offset: current ? Offset.zero : const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$level',
              style: AppFonts.style(
                fontSize: current ? 16 : 13,
                fontWeight: FontWeight.w800,
                color: current
                    ? Colors.white
                    : unlocked
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 12,
            child: stars <= 0
                ? null
                : current
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => StarIcon(
                            size: 9,
                            state:
                                i < stars ? StarState.earned : StarState.empty,
                          ),
                        ),
                      )
                    : const StarIcon(size: 11, state: StarState.earned),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _homeCard({Color? border, Color? fill}) {
  return BoxDecoration(
    color: fill ?? AppColors.surface,
    borderRadius: BorderRadius.circular(GameRadius.md),
    border: Border.all(color: border ?? AppColors.surfaceLight),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: AppColors.isDark ? 0.22 : 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// One line that invites the player into Daily without showing the full board.
class DailyPreviewCard extends StatefulWidget {
  const DailyPreviewCard({
    super.key,
    required this.title,
    required this.detail,
    required this.ready,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool ready;
  final VoidCallback onTap;

  @override
  State<DailyPreviewCard> createState() => _DailyPreviewCardState();
}

class _DailyPreviewCardState extends State<DailyPreviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _attention;

  @override
  void initState() {
    super.initState();
    _attention = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _playOnce());
  }

  @override
  void didUpdateWidget(covariant DailyPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) _playOnce();
  }

  void _playOnce() {
    if (!mounted || !widget.ready || GameMotion.reduce(context)) return;
    _attention.forward(from: 0);
  }

  @override
  void dispose() {
    _attention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _attention,
      builder: (context, child) {
        final wave = _attention.value <= 0
            ? 0.0
            : (1 - (_attention.value - 0.5).abs() * 2);
        return Transform.scale(scale: 1 + 0.015 * wave, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GameRadius.md),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(GameRadius.md),
            child: Ink(
              decoration: _homeCard(
                border: widget.ready
                    ? AppColors.accentGreen.withValues(alpha: 0.55)
                    : AppColors.surfaceLight,
                fill: widget.ready
                    ? Color.alphaBlend(
                        AppColors.accentGreen.withValues(alpha: 0.08),
                        AppColors.surface,
                      )
                    : null,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    const GameIcon(kind: GameIconKind.calendar, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GameTypography.section(GameColors.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.style(
                              fontSize: 13,
                              height: 1.3,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const GameIcon(kind: GameIconKind.chevron, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon and a short label. Status text stays off the home row.
class FeatureShortcut extends StatefulWidget {
  const FeatureShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final GameIconKind icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<FeatureShortcut> createState() => _FeatureShortcutState();
}

class _FeatureShortcutState extends State<FeatureShortcut> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.96 : 1,
      duration: GameMotion.tap,
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GameRadius.md),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (_down != v) setState(() => _down = v);
          },
          borderRadius: BorderRadius.circular(GameRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameRadius.md),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIcon(kind: widget.icon, size: 40),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GameTypography.caption(GameColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
  });

  final GameIconKind icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.96 : 1,
      duration: GameMotion.tap,
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GameRadius.md),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (_down != v) setState(() => _down = v);
          },
          borderRadius: BorderRadius.circular(GameRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameRadius.md),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameIcon(kind: widget.icon, size: 28),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTypography.caption(GameColors.text),
                ),
                if (widget.detail != null)
                  Text(
                    widget.detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppFonts.style(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (GameIconKind.home, l10n.navHome),
      (GameIconKind.calendar, l10n.navDaily),
      (GameIconKind.shop, l10n.navShop),
      (GameIconKind.more, l10n.navMore),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GameIconKind icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: selected ? 28 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Opacity(
            opacity: selected ? 1 : 0.55,
            child: GameIcon(kind: icon, size: selected ? 24 : 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MoreFeaturesGrid extends StatelessWidget {
  const MoreFeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = context.watch<ProgressRepository>();
    final earned = MetaRules.achievements
        .where((item) => item.unlocked(progress.achievementSnapshot))
        .length;
    final items = [
      _MoreItem(
        GameIconKind.wheel,
        l10n.navWheel,
        progress.canSpinWheel ? l10n.freeSpinToday : l10n.spunToday,
        '/wheel',
      ),
      _MoreItem(
        GameIconKind.album,
        l10n.navAlbum,
        l10n.shapesUncovered(progress.unlockedShapeCount),
        '/album',
      ),
      _MoreItem(
        GameIconKind.medal,
        l10n.navAwards,
        earned > 0 ? l10n.awardsEarned(earned) : null,
        '/achievements',
      ),
      _MoreItem(
        GameIconKind.settings,
        l10n.settings,
        null,
        '/settings',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final item in items)
          FeatureCard(
            icon: item.icon,
            label: item.label,
            detail: item.detail,
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.pushNamed(context, item.route);
            },
          ),
      ],
    );
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.label, this.detail, this.route);

  final GameIconKind icon;
  final String label;
  final String? detail;
  final String route;
}
