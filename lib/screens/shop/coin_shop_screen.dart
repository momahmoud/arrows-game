import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../core/board_style.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/game_state.dart';

class CoinShopScreen extends StatelessWidget {
  const CoinShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
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
                      'Shop',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.coins, color: Color(0xFFE2B93C), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.coins}',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _section('Power-ups'),
                    for (final type in PowerUpType.values)
                      _ShopRow(
                        title: _powerLabel(type),
                        detail: 'Owned ${progress.bonusPowerUp(type)} extra',
                        price: MetaRules.powerUpCost(type),
                        action: 'Buy',
                        enabled: progress.coins >= MetaRules.powerUpCost(type),
                        onTap: () {
                          if (!progress.buyPowerUp(type)) {
                            _broke(context);
                            return;
                          }
                          AudioManager.instance.playClick();
                        },
                      ),
                    _section('Hearts'),
                    _ShopRow(
                      title: 'Heart',
                      detail: progress.livesAreFull
                          ? 'Hearts are full'
                          : '${progress.lives} / ${progress.maxLives}',
                      price: MetaRules.heartCost,
                      action: 'Buy',
                      enabled: !progress.livesAreFull &&
                          progress.coins >= MetaRules.heartCost,
                      onTap: () {
                        if (!progress.buyHeart()) {
                          _broke(context);
                          return;
                        }
                        AudioManager.instance.playClick();
                      },
                    ),
                    _section('Arrow skins'),
                    for (final offer in BoardStyle.offers.where((o) => o.isSkin))
                      _cosmetic(context, progress, offer),
                    _section('Board themes'),
                    for (final offer in BoardStyle.offers.where((o) => !o.isSkin))
                      _cosmetic(context, progress, offer),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cosmetic(
    BuildContext context,
    ProgressRepository progress,
    CosmeticOffer offer,
  ) {
    final owned = progress.ownsCosmetic(offer.id);
    final equipped = progress.isCosmeticEquipped(offer);
    final free = BoardStyle.unlockedByProgress(offer, progress.highestUnlockedLevel);
    return _ShopRow(
      title: offer.name,
      detail: equipped
          ? 'Equipped'
          : owned
              ? offer.blurb
              : free
                  ? 'Unlocked by progress'
                  : 'Or reach level ${offer.unlockLevel}',
      price: owned ? 0 : offer.coinCost,
      action: equipped ? 'On' : owned || free ? 'Equip' : 'Buy',
      enabled: !equipped,
      onTap: () {
        final ok = owned || free
            ? progress.equipCosmetic(offer.id)
            : progress.buyCosmetic(offer.id);
        if (!ok) {
          _broke(context);
          return;
        }
        AudioManager.instance.playClick();
      },
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _broke(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Not enough coins', style: GoogleFonts.nunito()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _powerLabel(PowerUpType type) {
    switch (type) {
      case PowerUpType.hint:
        return 'Hint';
      case PowerUpType.eraser:
        return 'Eraser';
      case PowerUpType.wand:
        return 'Magic wand';
      case PowerUpType.ruler:
        return 'Ruler';
    }
  }
}

class _ShopRow extends StatelessWidget {
  final String title;
  final String detail;
  final int price;
  final String action;
  final bool enabled;
  final VoidCallback onTap;

  const _ShopRow({
    required this.title,
    required this.detail,
    required this.price,
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (price > 0) ...[
            const Icon(LucideIcons.coins, size: 14, color: Color(0xFFE2B93C)),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: enabled ? onTap : null,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
