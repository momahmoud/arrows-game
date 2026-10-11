import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../core/economy_config.dart';
import '../data/repositories/progress_repository.dart';

enum StorePurchaseStatus { purchased, pending, cancelled, failed, unavailable }

class StorePurchaseOutcome {
  const StorePurchaseOutcome(this.status);

  final StorePurchaseStatus status;
}

/// Play purchases for the existing coin packs and Remove Ads.
/// Prices come from the store. A finished purchase grants through
/// [ProgressRepository].
class PlayBilling extends ChangeNotifier {
  PlayBilling(this._progress);

  final ProgressRepository _progress;
  final InAppPurchase _store = InAppPurchase.instance;

  bool isReady = false;
  final Map<String, String> _prices = {};
  final Map<String, ProductDetails> _products = {};

  StreamSubscription<List<PurchaseDetails>>? _updates;
  Completer<StorePurchaseOutcome>? _pending;
  String? _waitingId;
  bool _started = false;

  bool get hasPrices => _prices.isNotEmpty;

  String? priceFor(String productId) => _prices[productId];

  static const List<String> productIds = [
    EconomyConfig.removeAdsId,
    EconomyConfig.coins1000Id,
    EconomyConfig.coins5000Id,
    EconomyConfig.coins10000Id,
  ];

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _updates = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        debugPrint('PlayBilling stream error: $error');
        _finish(const StorePurchaseOutcome(StorePurchaseStatus.failed));
      },
    );
    try {
      isReady = await _store.isAvailable();
      if (!isReady) {
        notifyListeners();
        return;
      }
      final response = await _store.queryProductDetails(productIds.toSet());
      _prices
        ..clear()
        ..addEntries(
          response.productDetails.map((product) => MapEntry(product.id, product.price)),
        );
      _products
        ..clear()
        ..addEntries(
          response.productDetails.map((product) => MapEntry(product.id, product)),
        );
      notifyListeners();
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('PlayBilling start error: $e');
      isReady = false;
      notifyListeners();
    }
  }

  Future<StorePurchaseOutcome> purchase(String productId) async {
    final details = _products[productId];
    if (!isReady || details == null) {
      return const StorePurchaseOutcome(StorePurchaseStatus.unavailable);
    }
    if (_pending != null) {
      return const StorePurchaseOutcome(StorePurchaseStatus.failed);
    }
    final completer = Completer<StorePurchaseOutcome>();
    _pending = completer;
    _waitingId = productId;
    try {
      final param = PurchaseParam(productDetails: details);
      final consumable = EconomyConfig.storeCoins(productId) != null;
      final launched = consumable
          ? await _store.buyConsumable(purchaseParam: param, autoConsume: false)
          : await _store.buyNonConsumable(purchaseParam: param);
      if (!launched) {
        _finish(const StorePurchaseOutcome(StorePurchaseStatus.failed));
      }
    } catch (e) {
      debugPrint('PlayBilling purchase error: $e');
      _finish(const StorePurchaseOutcome(StorePurchaseStatus.failed));
    }
    return completer.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final waiting = _waitingId != null &&
          (purchase.productID == _waitingId || purchase.productID.isEmpty);
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (waiting) {
            _finish(const StorePurchaseOutcome(StorePurchaseStatus.pending));
          }
          break;
        case PurchaseStatus.canceled:
          if (waiting) {
            _finish(const StorePurchaseOutcome(StorePurchaseStatus.cancelled));
          }
          break;
        case PurchaseStatus.error:
          if (waiting && _alreadyOwned(purchase)) {
            await _recoverOwned();
          } else if (waiting) {
            _finish(const StorePurchaseOutcome(StorePurchaseStatus.failed));
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(purchase);
          if (_waitingId != null && purchase.productID == _waitingId) {
            _finish(const StorePurchaseOutcome(StorePurchaseStatus.purchased));
          }
          break;
      }
    }
  }

  Future<void> _deliver(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final token = purchase.verificationData.serverVerificationData;
    if (productId.isEmpty || token.isEmpty || !productIds.contains(productId)) {
      return;
    }
    _progress.grantStorePurchase(
      productId: productId,
      transactionId: token,
    );
    final consumable = EconomyConfig.storeCoins(productId) != null;
    try {
      if (consumable && defaultTargetPlatform == TargetPlatform.android) {
        final android = _store
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await android.consumePurchase(purchase);
      } else if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    } catch (e) {
      debugPrint('PlayBilling finish error: $e');
    }
  }

  Future<void> _recoverOwned() async {
    final id = _waitingId;
    try {
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('PlayBilling restore error: $e');
    }
    if (id != null && _waitingId == id) {
      _finish(const StorePurchaseOutcome(StorePurchaseStatus.failed));
    }
  }

  bool _alreadyOwned(PurchaseDetails purchase) {
    final message = purchase.error?.message ?? '';
    return message.contains('itemAlreadyOwned');
  }

  void _finish(StorePurchaseOutcome outcome) {
    final pending = _pending;
    _pending = null;
    _waitingId = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(outcome);
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }
}
