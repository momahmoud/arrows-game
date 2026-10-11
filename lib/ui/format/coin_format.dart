import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware coin amounts. Arabic keeps its own digits and separators.
String formatCoins(BuildContext context, int amount, {bool signed = false}) {
  final locale = Localizations.localeOf(context).toString();
  final text = NumberFormat.decimalPattern(locale).format(amount);
  if (!signed || amount == 0) return text;
  final sign = amount > 0 ? '+' : '';
  return '$sign$text';
}
