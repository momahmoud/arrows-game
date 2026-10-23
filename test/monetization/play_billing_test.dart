import 'dart:async';
import 'dart:convert';

import 'package:arrow_escape/core/economy_config.dart';
import 'package:arrow_escape/data/repositories/progress_repository.dart';
import 'package:arrow_escape/monetization/play_billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Purchase delivery against a fake store. No live Play Billing is used.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Prefs prefs;
  late ProgressRepository progress;
  late _Store store;
  late PlayBilling billing;

  Future<void> boot([Map<String, Object> saved = const {}]) async {
    prefs = _Prefs(saved);
    progress = ProgressRepository(prefs);
    store = _Store();
    billing = PlayBilling(progress, store: store);
    await billing.start();
    await _settle();
  }

  group('coin pack purchase', () {
    test('grant is saved before the purchase is consumed', () async {
      await boot();
      store.onBuy = (id) => [_play(id, 'tok-1')];
      prefs.gate = Completer<void>();

      final outcome = billing.purchase(EconomyConfig.coins1000Id);
      await _settle();
      expect(store.consumed, isEmpty, reason: 'save has not finished');

      prefs.gate!.complete();
      prefs.gate = null;
      expect((await outcome).status, StorePurchaseStatus.purchased);
      expect(store.consumed, ['tok-1']);
      expect(progress.coins, 1000);
      expect(prefs.values['coins'], 1000);
      expect(_savedTokens(prefs), contains('tok-1'));
    });

    test('failed save keeps the purchase unconsumed and undoes the grant',
        () async {
      await boot();
      store.onBuy = (id) => [_play(id, 'tok-2')];
      prefs.fail = true;

      final outcome = await billing.purchase(EconomyConfig.coins1000Id);
      expect(outcome.status, StorePurchaseStatus.failed);
      expect(store.consumed, isEmpty);
      expect(progress.coins, 0);

      // The store delivers the same purchase again once saving works.
      prefs.fail = false;
      store.emit([_play(EconomyConfig.coins1000Id, 'tok-2', restored: true)]);
      await _settle();
      expect(progress.coins, 1000);
      expect(store.consumed, ['tok-2']);
    });

    test('the same purchase delivered twice grants once', () async {
      await boot();
      final purchase = _play(EconomyConfig.coins5000Id, 'tok-3');
      store.emit([purchase]);
      store.emit([purchase, _play(EconomyConfig.coins5000Id, 'tok-3')]);
      await _settle();
      expect(progress.coins, 5000);
      expect(_savedTokens(prefs), ['tok-3']);

      // Deliveries finished, so the next purchase is not blocked.
      store.onBuy = (id) => [_play(id, 'tok-3b')];
      final next = await billing
          .purchase(EconomyConfig.coins1000Id)
          .timeout(const Duration(seconds: 2));
      expect(next.status, StorePurchaseStatus.purchased);
      expect(progress.coins, 6000);
    });

    test('an already granted purchase is only consumed after restart',
        () async {
      await boot({
        'coins': 1000,
        'storeTransactions': jsonEncode(['tok-4']),
      });
      store.emit([_play(EconomyConfig.coins1000Id, 'tok-4', restored: true)]);
      await _settle();
      expect(progress.coins, 1000);
      expect(store.consumed, ['tok-4']);
    });

    test('a restored purchase that is still pending grants nothing', () async {
      await boot();
      store.emit([
        _play(
          EconomyConfig.coins10000Id,
          'tok-5',
          restored: true,
          state: PurchaseStateWrapper.pending,
        ),
      ]);
      await _settle();
      expect(progress.coins, 0);
      expect(store.consumed, isEmpty);
      expect(_savedTokens(prefs), isEmpty);
    });

    test('a store that never answers frees the next purchase', () async {
      prefs = _Prefs(const {});
      progress = ProgressRepository(prefs);
      store = _Store();
      billing = PlayBilling(
        progress,
        store: store,
        purchaseTimeout: const Duration(milliseconds: 50),
      );
      await billing.start();
      await _settle();
      store.onBuy = (id) => const [];

      final first = await billing.purchase(EconomyConfig.coins1000Id);
      expect(first.status, StorePurchaseStatus.pending);

      // The purchase finishing later is still delivered, and a new one works.
      store.emit([_play(EconomyConfig.coins1000Id, 'tok-late')]);
      await _settle();
      expect(progress.coins, 1000);
      store.onBuy = (id) => [_play(id, 'tok-next')];
      final next = await billing.purchase(EconomyConfig.coins1000Id);
      expect(next.status, StorePurchaseStatus.purchased);
    });

    test('cancel grants nothing', () async {
      await boot();
      store.onBuy =
          (id) => [_play(id, 'tok-6', status: PurchaseStatus.canceled)];
      final outcome = await billing.purchase(EconomyConfig.coins1000Id);
      expect(outcome.status, StorePurchaseStatus.cancelled);
      expect(progress.coins, 0);
      expect(store.consumed, isEmpty);
    });
  });

  group('remove ads', () {
    test('saved before acknowledgement, restored once', () async {
      await boot();
      store.onBuy = (id) => [_play(id, 'tok-ads')];
      prefs.gate = Completer<void>();

      final outcome = billing.purchase(EconomyConfig.removeAdsId);
      await _settle();
      expect(store.completed, isEmpty);
      prefs.gate!.complete();
      prefs.gate = null;

      expect((await outcome).status, StorePurchaseStatus.purchased);
      expect(progress.adsRemoved, isTrue);
      expect(prefs.values['adsRemoved'], isTrue);
      expect(store.completed, ['tok-ads']);
      expect(store.consumed, isEmpty);
    });

    test('a reinstall restores Remove Ads from the store', () async {
      await boot();
      store.emit([
        _play(
          EconomyConfig.removeAdsId,
          'tok-owned',
          restored: true,
          acknowledged: true,
        ),
      ]);
      await _settle();
      expect(progress.adsRemoved, isTrue);
      expect(store.completed, isEmpty, reason: 'already acknowledged');
    });
  });

  group('grantStorePurchase', () {
    test('rejects unknown products and empty tokens', () async {
      final repo = ProgressRepository(_Prefs());
      expect(
        await repo.grantStorePurchase(productId: 'other', transactionId: 't'),
        StoreGrant.rejected,
      );
      expect(
        await repo.grantStorePurchase(
          productId: EconomyConfig.coins1000Id,
          transactionId: '',
        ),
        StoreGrant.rejected,
      );
      expect(repo.coins, 0);
    });

    test('a failed save leaves no grant and no transaction behind', () async {
      final store = _Prefs()..fail = true;
      final repo = ProgressRepository(store);
      expect(
        await repo.grantStorePurchase(
          productId: EconomyConfig.coins1000Id,
          transactionId: 't1',
        ),
        StoreGrant.notSaved,
      );
      expect(repo.coins, 0);
      expect(repo.lifetimeCoins, 0);

      store.fail = false;
      expect(
        await repo.grantStorePurchase(
          productId: EconomyConfig.coins1000Id,
          transactionId: 't1',
        ),
        StoreGrant.granted,
      );
      expect(
        await repo.grantStorePurchase(
          productId: EconomyConfig.coins1000Id,
          transactionId: 't1',
        ),
        StoreGrant.alreadyGranted,
      );
      expect(repo.coins, 1000);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _savedTokens(_Prefs prefs) {
  final raw = prefs.values['storeTransactions'] as String?;
  if (raw == null) return const [];
  return (jsonDecode(raw) as List).cast<String>();
}

GooglePlayPurchaseDetails _play(
  String productId,
  String token, {
  bool restored = false,
  bool acknowledged = false,
  PurchaseStatus? status,
  PurchaseStateWrapper state = PurchaseStateWrapper.purchased,
}) {
  return GooglePlayPurchaseDetails(
    purchaseID: 'order-$token',
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: '0',
    billingClientPurchase: PurchaseWrapper(
      orderId: 'order-$token',
      packageName: 'test',
      purchaseTime: 0,
      purchaseToken: token,
      signature: '',
      products: [productId],
      isAutoRenewing: false,
      originalJson: '{}',
      isAcknowledged: acknowledged,
      purchaseState: state,
    ),
    status: status ??
        (restored ? PurchaseStatus.restored : PurchaseStatus.purchased),
  );
}

class _Store implements InAppPurchase {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  late final _android = _Android(this);
  final List<String> consumed = [];
  final List<String> completed = [];
  List<PurchaseDetails> Function(String productId)? onBuy;

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    return ProductDetailsResponse(
      productDetails: [
        for (final id in ids)
          ProductDetails(
            id: id,
            title: id,
            description: '',
            price: r'$1',
            rawPrice: 1,
            currencyCode: 'USD',
          ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    expect(autoConsume, isFalse);
    emit(onBuy!(purchaseParam.productDetails.id));
    return true;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    emit(onBuy!(purchaseParam.productDetails.id));
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase.verificationData.serverVerificationData);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getPlatformAddition) return _android;
    return super.noSuchMethod(invocation);
  }
}

class _Android implements InAppPurchaseAndroidPlatformAddition {
  _Android(this._store);

  final _Store _store;

  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase) async {
    _store.consumed.add(purchase.verificationData.serverVerificationData);
    return const BillingResultWrapper(responseCode: BillingResponse.ok);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory preferences whose writes can be held or made to fail.
class _Prefs implements SharedPreferences {
  _Prefs([Map<String, Object> initial = const {}])
      : values = {'soundEnabled': false, 'musicEnabled': false, ...initial};

  final Map<String, Object> values;
  bool fail = false;
  Completer<void>? gate;

  Future<bool> _write(String key, Object value) async {
    final wait = gate;
    if (wait != null) await wait.future;
    if (fail) return false;
    values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setInt(String key, int value) => _write(key, value);

  @override
  Future<bool> setBool(String key, bool value) => _write(key, value);

  @override
  Future<bool> setString(String key, String value) => _write(key, value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
