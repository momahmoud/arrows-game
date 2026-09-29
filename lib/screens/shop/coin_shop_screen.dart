import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../core/board_style.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/game_state.dart';
import '../../l10n/l10n.dart';

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
                      context.l10n.shop,
                      style: AppFonts.style(
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
                      style: AppFonts.style(
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
                    _section(context.l10n.shopPowerUps),
                    for (final type in PowerUpType.values)
                      _ShopRow(
                        title: context.l10n.powerUp(type),
                        detail: context.l10n.ownedExtra(progress.bonusPowerUp(type)),
                        price: MetaRules.powerUpCost(type),
                        action: context.l10n.buy,
                        enabled: progress.coins >= MetaRules.powerUpCost(type),
                        onTap: () {
                          if (!progress.buyPowerUp(type)) {
                            _broke(context);
                            return;
                          }
                          AudioManager.instance.playClick();
                        },
                      ),
                    _section(context.l10n.shopHearts),
                    _ShopRow(
                      title: context.l10n.heart,
                      detail: progress.livesAreFull
                          ? context.l10n.heartsFull
                          : '${progress.lives} / ${progress.maxLives}',
                      price: MetaRules.heartCost,
                      action: context.l10n.buy,
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
                    _section(context.l10n.arrowSkins),
                    for (final offer in BoardStyle.offers.where((o) => o.isSkin))
                      _cosmetic(context, progress, offer),
                    _section(context.l10n.boardThemes),
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
    final l10n = context.l10n;
    return _ShopRow(
      title: l10n.cosmeticName(offer.id, offer.name),
      detail: equipped
          ? l10n.equipped
          : owned
              ? l10n.cosmeticBlurb(offer.id, offer.blurb)
              : free
                  ? l10n.unlockedByProgress
                  : l10n.orReachLevel(offer.unlockLevel),
      price: owned ? 0 : offer.coinCost,
      action: equipped
          ? l10n.equippedShort
          : owned || free
              ? l10n.equip
              : l10n.buy,
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
        style: AppFonts.style(
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
        content: Text(context.l10n.notEnoughCoins, style: AppFonts.style()),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  style: AppFonts.style(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: AppFonts.style(
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
              style: AppFonts.style(fontWeight: FontWeight.w800),
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
