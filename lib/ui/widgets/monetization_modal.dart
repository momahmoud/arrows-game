import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ads/ad_manager.dart';
import '../../core/constants.dart';
import '../../core/app_fonts.dart';
import '../../core/audio_manager.dart';
import '../../core/economy_config.dart';
import '../../data/repositories/progress_repository.dart';
import '../../game/game_state.dart';
import '../../l10n/l10n.dart';
import '../../monetization/monetization_policy.dart';
import '../../monetization/play_billing.dart';
import '../game_ui.dart';

/// Shared surface for one monetization decision.
class MonetizationModal extends StatelessWidget {
  const MonetizationModal({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.note,
    this.value,
    required this.actions,
    this.dismissLabel,
    this.onDismiss,
  });

  final GameIconKind icon;
  final String title;
  final String body;
  final String? note;
  final Widget? value;
  final List<Widget> actions;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GameDialog(
      icon: icon,
      iconSize: GameIconSizes.xl,
      title: title,
      message: body,
      note: note,
      body: value,
      actions: actions,
      dismissLabel: dismissLabel,
      onDismiss: onDismiss,
    );
  }
}

class MonetizationPresenter {
  MonetizationPresenter._();

  /// The Remove Ads popup, when the monetization policy allows one.
  static Future<void> removeAds(BuildContext context) async {
    final policy = context.read<MonetizationPolicy>();
    final progress = context.read<ProgressRepository>();
    if (!policy.tryBegin(
      MonetizationOffer.removeAds,
      adsRemoved: progress.adsRemoved,
    )) {
      return;
    }
    if (!context.mounted) return;
    await showRemoveAdsOffer(context);
  }

  /// The Remove Ads popup itself. The caller decides when it may appear:
  /// the prompt coordinator, which keeps it off ads and reviews.
  static Future<void> showRemoveAdsOffer(BuildContext context) async {
    final policy = context.read<MonetizationPolicy>();
    final l10n = context.l10n;
    final price =
        context.read<PlayBilling>().priceFor(EconomyConfig.removeAdsId);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MonetizationModal(
        icon: GameIconKind.removeAds,
        title: l10n.removeAds,
        body: l10n.removeAdsBody,
        note: l10n.rewardedAdsRemain,
        value: Text(
          price ?? l10n.storeSoon,
          textAlign: TextAlign.center,
          style: GameTypography.section(GameColors.text),
        ),
        actions: [
          GameButton(
            label: l10n.removeAds,
            icon: GameIconKind.removeAds,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext);
              buy(context, EconomyConfig.removeAdsId);
            },
          ),
        ],
        dismissLabel: l10n.maybeLater,
        onDismiss: () => Navigator.pop(dialogContext),
      ),
    );
    policy.finish(MonetizationOffer.removeAds);
    MonetizationEvents.log('monetization_offer_dismissed');
  }

  static Future<void> lowCoins(
    BuildContext context, {
    required int need,
    VoidCallback? onGetCoins,
  }) async {
    final policy = context.read<MonetizationPolicy>();
    final progress = context.read<ProgressRepository>();
    final ads = context.read<AdManager>();
    if (!policy.tryBegin(MonetizationOffer.lowCoins)) {
      _quiet(context, context.l10n.notEnoughCoins);
      return;
    }
    if (!context.mounted) return;
    final l10n = context.l10n;
    final canWatch = ads.isRewardedAvailable && progress.canClaimRewardedCoins;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MonetizationModal(
        icon: GameIconKind.coin,
        title: l10n.notEnoughCoins,
        body: l10n.youNeedCoins(need),
        value: Text(
          l10n.currentBalance(progress.coins),
          textAlign: TextAlign.center,
          style: GameTypography.section(GameColors.rewardText),
        ),
        actions: [
          if (canWatch)
            GameButton(
              label: l10n.watchVideo,
              subtitle: l10n.coinsAmount(EconomyConfig.rewardedAdCoins),
              icon: GameIconKind.watchAd,
              onPressed: () {
                AudioManager.instance.playClick();
                Navigator.pop(dialogContext);
                MonetizationEvents.log('rewarded_offer_shown');
                ads.showRewardedWithLoader(
                  context,
                  onRewarded: () {
                    if (!context.mounted) return;
                    progress.claimRewardedCoins();
                  },
                );
              },
            ),
          GameButton(
            label: l10n.getCoins,
            icon: GameIconKind.shop,
            variant: GameButtonVariant.secondary,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext);
              onGetCoins?.call();
            },
          ),
        ],
        dismissLabel: l10n.notNow,
        onDismiss: () => Navigator.pop(dialogContext),
      ),
    );
    policy.finish(MonetizationOffer.lowCoins);
    MonetizationEvents.log('monetization_offer_dismissed');
  }

  static Future<bool> outOfBooster(
    BuildContext context, {
    required PowerUpType type,
    required VoidCallback onGranted,
  }) async {
    final policy = context.read<MonetizationPolicy>();
    final progress = context.read<ProgressRepository>();
    final ads = context.read<AdManager>();
    final cost = _cost(type);
    if (!policy.tryBegin(MonetizationOffer.booster)) return false;
    if (!context.mounted) {
      policy.finish(MonetizationOffer.booster);
      return false;
    }
    final l10n = context.l10n;
    final name = l10n.powerUp(type);
    final canWatch = ads.isRewardedAvailable;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MonetizationModal(
        icon: _boosterIcon(type),
        title: l10n.outOfItem(name),
        body: l10n.getAnother(name),
        actions: [
          GameButton(
            label: l10n.getWithCoins,
            subtitle: l10n.coinsAmount(cost),
            icon: GameIconKind.coin,
            onPressed: () {
              AudioManager.instance.playClick();
              if (!progress.buyPowerUp(type)) {
                Navigator.pop(dialogContext);
                policy.finish(MonetizationOffer.booster);
                lowCoins(
                  context,
                  need: cost,
                  onGetCoins: () {
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, '/shop');
                  },
                );
                return;
              }
              onGranted();
              Navigator.pop(dialogContext);
            },
          ),
          if (canWatch)
            GameButton(
              label: l10n.watchVideo,
              icon: GameIconKind.watchAd,
              variant: GameButtonVariant.secondary,
              onPressed: () {
                AudioManager.instance.playClick();
                Navigator.pop(dialogContext);
                ads.showRewardedWithLoader(
                  context,
                  onRewarded: () {
                    onGranted();
                    progress.addBonusPowerUp(
                      type,
                      AppConstants.powerUpsPerRewardedAd,
                    );
                  },
                );
              },
            ),
        ],
        dismissLabel: l10n.notNow,
        onDismiss: () => Navigator.pop(dialogContext),
      ),
    );
    policy.finish(MonetizationOffer.booster);
    MonetizationEvents.log('monetization_offer_dismissed');
    return true;
  }

  static void unavailable(BuildContext context) {
    MonetizationEvents.log('purchase_started');
    MonetizationEvents.log('purchase_failed');
    if (!context.mounted) return;
    _quiet(context, context.l10n.purchaseCouldNot);
  }

  /// Starts a Play purchase for an existing product. Coins and Remove Ads
  /// are granted only after Play reports the purchase as complete.
  static Future<void> buy(BuildContext context, String productId) async {
    final billing = context.read<PlayBilling>();
    if (!billing.isReady || billing.priceFor(productId) == null) {
      unavailable(context);
      return;
    }
    MonetizationEvents.log('purchase_started');
    final outcome = await billing.purchase(productId);
    if (!context.mounted) return;
    switch (outcome.status) {
      case StorePurchaseStatus.purchased:
        MonetizationEvents.log('purchase_completed');
        _quiet(context, context.l10n.purchaseCompleteTitle);
        return;
      case StorePurchaseStatus.cancelled:
      case StorePurchaseStatus.pending:
        return;
      case StorePurchaseStatus.failed:
      case StorePurchaseStatus.unavailable:
        MonetizationEvents.log('purchase_failed');
        _quiet(context, context.l10n.purchaseCouldNot);
    }
  }

  static int _cost(PowerUpType type) {
    switch (type) {
      case PowerUpType.hint:
        return EconomyConfig.hintCost;
      case PowerUpType.eraser:
        return EconomyConfig.eraserCost;
      case PowerUpType.wand:
        return EconomyConfig.wandCost;
      case PowerUpType.ruler:
        return EconomyConfig.rulerCost;
    }
  }

  static GameIconKind _boosterIcon(PowerUpType type) {
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

  static void _quiet(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.style()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
