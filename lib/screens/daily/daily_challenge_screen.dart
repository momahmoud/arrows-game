import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      AudioManager.instance.playClick();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    'Daily Challenge',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.streakDays}-day streak',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                done
                    ? 'Today’s reward is already claimed'
                    : 'Clear level $level for +$reward coins',
                style: GoogleFonts.nunito(color: AppColors.textMuted),
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: done
                    ? null
                    : () {
                        AudioManager.instance.playClick();
                        Navigator.pushNamed(
                          context,
                          '/game',
                          arguments: {'level': level, 'daily': true},
                        );
                      },
                child: Text(done ? 'Come back tomorrow' : 'Play today’s level'),
              ),
              const SizedBox(height: 8),
              Text(
                'Rewards climb with your streak, up to day 30.',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
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
            color: marked ? const Color(0xFF7D9B76) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: const Color(0xFFE2B93C), width: 2) : null,
          ),
          child: Text(
            '$day',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: marked ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}
