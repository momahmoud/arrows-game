import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
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
/// [ProgressRepository], and is consumed or acknowledged only after that
/// grant is saved. Checks are client-side; there is no server verification.
class PlayBilling extends ChangeNotifier {
  PlayBilling(this._progress, {InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  final ProgressRepository _progress;
  final InAppPurchase _store;
  final Map<String, Future<bool>> _delivering = {};

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
          response.productDetails
              .map((product) => MapEntry(product.id, product.price)),
        );
      _products
        ..clear()
        ..addEntries(
          response.productDetails
              .map((product) => MapEntry(product.id, product)),
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
          final delivered = await _deliver(purchase);
          if (purchase.status == PurchaseStatus.purchased &&
              _waitingId != null &&
              purchase.productID == _waitingId) {
            _finish(StorePurchaseOutcome(
              delivered
                  ? StorePurchaseStatus.purchased
                  : StorePurchaseStatus.failed,
            ));
          }
          break;
      }
    }
  }

  /// True when the purchase is granted (now or earlier). The same purchase
  /// arriving twice at once shares one delivery.
  Future<bool> _deliver(PurchaseDetails purchase) {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return Future.value(false);
    return _delivering[token] ??=
        _deliverOnce(purchase, token).whenComplete(() {
      _delivering.remove(token);
    });
  }

  Future<bool> _deliverOnce(PurchaseDetails purchase, String token) async {
    final productId = purchase.productID;
    if (productId.isEmpty || !productIds.contains(productId)) return false;
    if (!_isPaid(purchase)) return false;
    final grant = await _progress.grantStorePurchase(
      productId: productId,
      transactionId: token,
    );
    if (grant != StoreGrant.granted && grant != StoreGrant.alreadyGranted) {
      return false;
    }
    final consumable = EconomyConfig.storeCoins(productId) != null;
    try {
      if (consumable && defaultTargetPlatform == TargetPlatform.android) {
        final android =
            _store.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final result = await android.consumePurchase(purchase);
        if (result.responseCode != BillingResponse.ok) {
          debugPrint('PlayBilling consume failed: ${result.responseCode}');
        }
      } else if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    } catch (e) {
      debugPrint('PlayBilling finish error: $e');
    }
    return true;
  }

  /// Android restore reports every owned purchase as restored, including
  /// ones whose payment is still pending.
  bool _isPaid(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseState ==
          PurchaseStateWrapper.purchased;
    }
    return true;
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
