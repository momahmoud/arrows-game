import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/economy_config.dart';
import '../data/repositories/progress_repository.dart';
import '../ui/widgets/monetization_modal.dart';
import 'play_billing.dart';
import 'prompts/prompt_coordinator.dart';

/// Offers Remove Ads right after an interstitial closed, when the rules
/// allow: capped, never to someone who bought, never over a review request.
/// Call only on a screen the player is still looking at.
Future<void> offerRemoveAdsAfterInterstitial(BuildContext context) async {
  final billing = context.read<PlayBilling>();
  final price = billing.priceFor(EconomyConfig.removeAdsId);
  // Nothing to sell without a store price.
  if (!billing.isReady || price == null) return;
  await PromptCoordinator.instance.offerRemoveAds(
    adsRemoved: context.read<ProgressRepository>().adsRemoved,
    show: () async {
      if (!context.mounted) return;
      await MonetizationPresenter.showRemoveAdsOffer(context);
    },
  );
}
