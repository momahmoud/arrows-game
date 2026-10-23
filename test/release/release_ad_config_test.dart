@Tags(['release'])
library;

import 'package:arrow_escape/core/ad_secrets_example.dart' as example;
import 'package:arrow_escape/core/ad_secrets_example.dart' as release;
import 'package:arrow_escape/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// Google's public AdMob sample publisher. Never valid in a release build.
const _googleTestPublisher = '3940256099942544';

final _appId = RegExp(r'^ca-app-pub-(\d{16})~\d{10}$');
final _unitId = RegExp(r'^ca-app-pub-(\d{16})/\d{10}$');

void main() {
  final units = {
    'banner': release.AdSecrets.admobBannerUnitId,
    'interstitial': release.AdSecrets.admobInterstitialUnitId,
    'rewarded': release.AdSecrets.admobRewardedUnitId,
  };

  test('lib/core/ad_secrets.dart is not the example placeholder', () {
    expect(
      [
        release.AdSecrets.admobAppIdAndroid,
        ...units.values,
        release.AdSecrets.unityGameIdAndroid,
      ],
      isNot(equals([
        example.AdSecrets.admobAppIdAndroid,
        example.AdSecrets.admobBannerUnitId,
        example.AdSecrets.admobInterstitialUnitId,
        example.AdSecrets.admobRewardedUnitId,
        example.AdSecrets.unityGameIdAndroid,
      ])),
    );
  });

  test('AdMob IDs are well-formed production IDs from one publisher', () {
    final app = _appId.firstMatch(release.AdSecrets.admobAppIdAndroid);
    expect(app, isNotNull, reason: 'admobAppIdAndroid is malformed');
    final publisher = app!.group(1);
    expect(publisher, isNot(_googleTestPublisher));
    units.forEach((name, id) {
      final unit = _unitId.firstMatch(id);
      expect(unit, isNotNull, reason: '$name unit ID is malformed');
      expect(unit!.group(1), publisher,
          reason: '$name unit ID belongs to a different publisher');
    });
  });

  test('Unity game ID is numeric', () {
    expect(release.AdSecrets.unityGameIdAndroid, matches(RegExp(r'^\d+$')));
  });

  test('LevelPlay app key and ad units are set', () {
    // An empty key means ads are off, which must not ship by accident.
    expect(AppConstants.levelPlayAppKey, isNotEmpty);
    expect(AppConstants.levelPlayBannerAdUnitId, isNotEmpty);
    expect(AppConstants.levelPlayInterstitialAdUnitId, isNotEmpty);
    expect(AppConstants.levelPlayRewardedAdUnitId, isNotEmpty);
  });
}
