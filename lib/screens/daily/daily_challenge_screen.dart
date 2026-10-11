import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../core/economy_config.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key, this.embedded = false});

  /// Hides the back control when this screen is a tab, not a pushed route.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final now = DateTime.now();
    final level = MetaRules.dailyLevel(now);
    final reward = MetaRules.dailyCoinReward(
      progress.streakDays == 0 ? 1 : progress.streakDays,
    );
    final done = progress.dailyClaimedToday;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final lead = DateTime(now.year, now.month, 1).weekday - 1;
    final pending = progress.pendingLoginDay;
    final loginCoins =
        pending == null ? 0 : EconomyConfig.loginCoins(pending);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GameScreenHeader(
                title: context.l10n.dailyChallenge,
                showBack: !embedded,
              ),
              const SizedBox(height: 8),
              _ChallengeCard(
                reward: context.l10n.dailyGoal(level, reward),
                claimed: done,
                streak: progress.streakDays,
                onPlay: () {
                  AudioManager.instance.playClick();
                  Navigator.pushNamed(
                    context,
                    '/game',
                    arguments: {'level': level, 'daily': true},
                  );
                },
              ),
              const SizedBox(height: 16),
              _Calendar(
                year: now.year,
                month: now.month,
                days: daysInMonth,
                lead: lead,
                today: now.day,
                played: progress.playedDays,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.dailyLogin,
                style: GameTypography.section(GameColors.text),
              ),
              const SizedBox(height: 8),
              DailyRewardCalendar(
                amounts: EconomyConfig.loginRewards,
                claimedThrough: progress.loginCycleDay,
                claimedToday: progress.loginClaimedToday,
                pendingDay: pending,
                strip: true,
                onClaim: () {
                  AudioManager.instance.playClick();
                  progress.claimLoginReward();
                },
              ),
              const SizedBox(height: 12),
              GameButton(
                icon: GameIconKind.coin,
                label: pending == null
                    ? context.l10n.rewardClaimed
                    : '${context.l10n.claim} ${formatCoins(context, loginCoins, signed: true)}',
                onPressed: pending == null
                    ? null
                    : () {
                        AudioManager.instance.playClick();
                        final from = CoinFly.of(context);
                        progress.claimLoginReward();
                        if (from != null) CoinFly.burst(context, from: from);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.reward,
    required this.claimed,
    required this.streak,
    required this.onPlay,
  });

  final String reward;
  final bool claimed;
  final int streak;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GameDecor.card(highlight: !claimed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const GameIcon(kind: GameIconKind.streak, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.dayStreak(streak),
                    style: GameTypography.caption(GameColors.textMuted),
                  ),
                ],
              ),
            ),
          Text(
            claimed ? l10n.dailyClaimed : reward,
            style: GameTypography.body(GameColors.text),
          ),
          const SizedBox(height: 12),
          GameButton(
            icon: claimed ? GameIconKind.check : GameIconKind.play,
            label: claimed ? l10n.comeBackTomorrow : l10n.playTodaysLevel,
            onPressed: claimed ? null : onPlay,
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final int year;
  final int month;
  final int days;
  final int lead;
  final int today;
  final Set<String> played;

  const _Calendar({
    required this.year,
    required this.month,
    required this.days,
    required this.lead,
    required this.today,
    required this.played,
  });

  @override
  Widget build(BuildContext context) {
    final cells = lead + days;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: cells,
      itemBuilder: (context, index) {
        if (index < lead) return const SizedBox.shrink();
        final day = index - lead + 1;
        final key =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final marked = played.contains(key);
        final isToday = day == today;
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: marked
                ? AppColors.accentGreen.withValues(alpha: 0.85)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: AppColors.accent, width: 2)
                : Border.all(color: AppColors.surfaceLight),
          ),
          child: Text(
            '$day',
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              color: marked ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}
