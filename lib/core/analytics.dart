import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Best-effort Firebase Analytics events; a no-op when Firebase isn't
/// initialised.
class Analytics {
  Analytics._();

  static void logEvent(String name, [Map<String, Object?>? params]) {
    if (kDebugMode) debugPrint('analytics: $name ${params ?? ''}');
    try {
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: _clean(params))
          .ignore();
    } catch (_) {
      // Firebase not initialised: telemetry is best-effort.
    }
  }

  /// An ad failed to load; [format] is banner, interstitial or rewarded.
  static void logAdLoadFailed(String format, int errorCode, String message) {
    logEvent('ad_load_failed', {
      'ad_format': format,
      'error_code': errorCode,
      'error_message': message,
    });
  }

  /// Impression-level revenue from LevelPlay, sent as Firebase's standard
  /// `ad_impression` event so it feeds the ad revenue reports.
  static void logAdImpression({
    required String? network,
    required String? format,
    required String? adUnitName,
    required double? revenueUsd,
    String? placement,
  }) {
    logEvent('ad_impression', {
      'ad_platform': 'LevelPlay',
      'ad_source': network,
      'ad_format': format,
      'ad_unit_name': adUnitName,
      'placement': placement,
      'value': revenueUsd,
      'currency': 'USD',
    });
  }

  /// Firebase accepts only string and number params (max 100 chars).
  static Map<String, Object>? _clean(Map<String, Object?>? params) {
    if (params == null) return null;
    final out = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is num) {
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 1 : 0;
      } else {
        final text = value.toString();
        out[key] = text.length > 100 ? text.substring(0, 100) : text;
      }
    });
    return out;
  }
}
