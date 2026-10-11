import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// One offer at a time. Dismissed offers wait out a cooldown.
enum MonetizationOffer {
  removeAds,
  lowCoins,
  booster,
  rewardedCoins,
  storePurchase,
}

class MonetizationEvents {
  MonetizationEvents._();

  static void log(String name) {
    debugPrint('monetization:$name');
  }
}

class MonetizationPolicy extends ChangeNotifier {
  static const cooldown = Duration(minutes: 3);

  MonetizationOffer? _open;
  final Map<MonetizationOffer, DateTime> _closedAt = {};
  int _clearsThisSession = 0;
  bool _lastWasFailure = false;
  bool _removeAdsOffered = false;

  bool get busy => _open != null;

  void noteClear() {
    _clearsThisSession++;
    _lastWasFailure = false;
  }

  void noteFailure() {
    _lastWasFailure = true;
  }

  /// Starts an offer when policy allows. False means stay quiet.
  bool tryBegin(
    MonetizationOffer offer, {
    bool adsRemoved = false,
  }) {
    if (_open != null) return false;
    if (offer == MonetizationOffer.removeAds) {
      if (adsRemoved || _removeAdsOffered) return false;
      if (_lastWasFailure) return false;
      if (_clearsThisSession < AppConstants.interstitialEveryNLevels) {
        return false;
      }
    }
    final closed = _closedAt[offer];
    if (closed != null && DateTime.now().difference(closed) < cooldown) {
      return false;
    }
    _open = offer;
    if (offer == MonetizationOffer.removeAds) _removeAdsOffered = true;
    MonetizationEvents.log(_eventShown(offer));
    return true;
  }

  void finish(MonetizationOffer offer) {
    if (_open == offer) _open = null;
    _closedAt[offer] = DateTime.now();
  }

  String _eventShown(MonetizationOffer offer) {
    switch (offer) {
      case MonetizationOffer.removeAds:
        return 'remove_ads_offer_shown';
      case MonetizationOffer.lowCoins:
        return 'low_coin_offer_shown';
      case MonetizationOffer.booster:
        return 'booster_offer_shown';
      case MonetizationOffer.rewardedCoins:
        return 'rewarded_offer_shown';
      case MonetizationOffer.storePurchase:
        return 'coin_offer_shown';
    }
  }
}
