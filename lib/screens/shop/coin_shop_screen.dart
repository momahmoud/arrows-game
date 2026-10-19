import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ads/ad_manager.dart';
import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/audio_manager.dart';
import '../../core/economy_config.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/game_state.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';
import '../../ui/widgets/gameplay_hud.dart';
import '../../monetization/play_billing.dart';
import '../../ui/widgets/monetization_modal.dart';

class CoinShopScreen extends StatelessWidget {
  const CoinShopScreen({super.key, this.embedded = false});

  /// Hides the back control when this screen is a tab, not a pushed route.
  final bool embedded;

  static final GlobalKey _rewardKey = GlobalKey();
  static final GlobalKey _packsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final billing = context.watch<PlayBilling>();
    final ads = context.read<AdManager>();
    final l10n = context.l10n;
    final packs = EconomyConfig.storeCoinPacks.entries.toList();
    final rewarded = ads.isRewardedAvailable;
    final storeReady = billing.hasPrices;

    return Scaffold(
      body: Container(
        color: AppColors.isDark ? null : const Color(0xFFFFFFFF),
        decoration: AppColors.isDark
            ? BoxDecoration(gradient: AppColors.bgGradient)
            : null,
        child: SafeArea(
          child: Column(
            children: [
              _ShopHeader(
                title: l10n.shop,
                coins: progress.coins,
                showBack: !embedded,
                onCoins: _revealPacks,
                onSettings: () {
                  AudioManager.instance.playClick();
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (rewarded) ...[
                      _section(l10n.getCoins, first: true),
                      KeyedSubtree(
                        key: _rewardKey,
                        child: WatchAdRewardCard(
                          coins: EconomyConfig.rewardedAdCoins,
                          enabled: progress.canClaimRewardedCoins,
                          onWatch: () => _watchAd(context, progress, ads),
                        ),
                      ),
                    ],
                    _section(l10n.shopCoins, first: !rewarded),
                    KeyedSubtree(
                      key: _packsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!storeReady)
                            Text(
                              l10n.storeSoon,
                              style:
                                  GameTypography.caption(GameColors.textMuted),
                            ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth >= 480 ? 3 : 2;
                              return _productGrid(
                                columns: columns,
                                children: [
                                  for (final pack in packs)
                                    CoinPackCard(
                                      coins: pack.value,
                                      price: billing.priceFor(pack.key),
                                      action: l10n.buy,
                                      onBuy: () => MonetizationPresenter.buy(
                                        context,
                                        pack.key,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    _section(l10n.shopPowerUps),
                    _productGrid(
                      columns: 2,
                      children: [
                        for (final type in PowerUpType.values)
                          ShopBoosterTile(
                            icon: _powerIcon(type),
                            title: l10n.powerUp(type),
                            owned: l10n.ownedExtra(progress.bonusPowerUp(type)),
                            price: MetaRules.powerUpCost(type),
                            action: l10n.buy,
                            onBuy: () {
                              if (!progress.buyPowerUp(type)) {
                                _broke(context, MetaRules.powerUpCost(type));
                                return;
                              }
                              AudioManager.instance.playClick();
                            },
                          ),
                      ],
                    ),
                    if (!progress.adsRemoved) ...[
                      _section(l10n.removeAds),
                      RemoveAdsCard(
                        active: false,
                        price: billing.priceFor(EconomyConfig.removeAdsId),
                        onPurchase: () => MonetizationPresenter.buy(
                          context,
                          EconomyConfig.removeAdsId,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _revealPacks() {
    AudioManager.instance.playClick();
    final target = _packsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  void _watchAd(
    BuildContext context,
    ProgressRepository progress,
    AdManager ads,
  ) {
    var rewarded = false;
    ads.showRewardedWithLoader(
      context,
      onRewarded: () {
        if (rewarded || !context.mounted) return;
        rewarded = true;
        final box = _rewardKey.currentContext?.findRenderObject() as RenderBox?;
        final from = box == null || !box.hasSize
            ? null
            : box.localToGlobal(box.size.center(Offset.zero));
        progress.claimRewardedCoins();
        if (from != null && context.mounted) {
          CoinFly.burst(context, from: from);
        }
      },
    );
  }

  Widget _section(String title, {bool first = false}) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 8 : 24, bottom: 10),
      child: Text(title, style: GameTypography.section(GameColors.text)),
    );
  }

  Widget _productGrid({
    required int columns,
    required List<Widget> children,
  }) {
    const gap = 12.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final end = math.min(i + columns, children.length);
      final slice = children.sublist(i, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: gap),
              Expanded(
                child: j < slice.length ? slice[j] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (end < children.length) rows.add(const SizedBox(height: gap));
    }
    return Column(children: rows);
  }

  GameIconKind _powerIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.hint:
        return GameIconKind.hint;
      case PowerUpType.eraser:
        return GameIconKind.remove;
      case PowerUpType.wand:
        return GameIconKind.wand;
      case PowerUpType.ruler:
        return GameIconKind.ruler;
    }
  }

  void _broke(BuildContext context, int need) {
    MonetizationPresenter.lowCoins(context, need: need);
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.title,
    required this.coins,
    required this.showBack,
    required this.onCoins,
    required this.onSettings,
  });

  final String title;
  final int coins;
  final bool showBack;
  final VoidCallback onCoins;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                GameIconButton(
                  kind: GameIconKind.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () {
                    AudioManager.instance.playClick();
                    Navigator.pop(context);
                  },
                )
              else
                const SizedBox(width: 48),
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
              GameIconButton(
                kind: GameIconKind.settings,
                tooltip: context.l10n.settings,
                onPressed: onSettings,
              ),
            ],
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.style(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
