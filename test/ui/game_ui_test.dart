import 'package:arrow_escape/core/economy_config.dart';
import 'package:arrow_escape/l10n/l10n.dart';
import 'package:arrow_escape/ui/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icons and reward chrome paint in English and Arabic', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in const [Locale('en'), Locale('ar')]) {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ListView(
            children: [
              GameButton(
                label: locale.languageCode == 'ar' ? 'المرحلة التالية' : 'Next Level',
                icon: GameIconKind.play,
                onPressed: () {},
              ),
              RewardButton(
                label: locale.languageCode == 'ar' ? 'شاهد فيديو' : 'Watch a Video',
                coins: EconomyConfig.rewardedAdCoins,
                onPressed: () {},
              ),
              const CoinDisplay(amount: 2450, anchor: true),
              DailyRewardCalendar(
                amounts: EconomyConfig.loginRewards,
                claimedThrough: 2,
                claimedToday: false,
                pendingDay: 3,
                strip: true,
                onClaim: () {},
              ),
              DailyRewardCalendar(
                amounts: EconomyConfig.loginRewards,
                claimedThrough: 2,
                claimedToday: false,
                pendingDay: 3,
                onClaim: () {},
              ),
              const RemoveAdsCard(active: false),
              WatchAdRewardCard(
                coins: EconomyConfig.rewardedAdCoins,
                enabled: true,
                onWatch: () {},
              ),
              LevelCompleteReward(stars: 3, coins: EconomyConfig.normalClear),
              for (final kind in GameIconKind.values)
                GameIcon(kind: kind, size: 48),
              const GameIcon(key: Key('icon-end'), kind: GameIconKind.check, size: 48),
            ],
          ),
        ),
      ));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('icon-end')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: locale.languageCode);
    }
  });
}
