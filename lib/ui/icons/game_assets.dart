import 'game_icon_kind.dart';

/// One map from a game symbol to artwork.
///
/// Raster files and SVGs live in `assets/images/icons`.
/// Kinds with no file stay on the vector painter.
class GameArt {
  const GameArt(this.asset, {this.tone = GameArtTone.full});

  final String asset;
  final GameArtTone tone;
}

enum GameArtTone { full, dim, empty }

const _icons = 'assets/images/icons';

const Map<GameIconKind, GameArt> gameArt = {
  GameIconKind.coin: GameArt('$_icons/coin.png'),
  GameIconKind.coinFlying: GameArt('$_icons/coin.png'),
  GameIconKind.coinPurchase: GameArt('$_icons/coin.png'),
  GameIconKind.getCoins: GameArt('$_icons/coin.png'),
  GameIconKind.earnCoins: GameArt('$_icons/coin.png'),
  GameIconKind.coinBurst: GameArt('$_icons/coin.png'),
  GameIconKind.coinBonus: GameArt('$_icons/coin.png'),
  GameIconKind.freeCoins: GameArt('$_icons/coin.png'),
  GameIconKind.coinStack: GameArt('$_icons/coin_stack.png'),
  GameIconKind.doubleReward: GameArt('$_icons/coin_stack.png'),
  GameIconKind.coinStackLarge: GameArt('$_icons/coin_stack_gold.png'),
  GameIconKind.coinPile: GameArt('$_icons/coin_stack_gold.png'),
  GameIconKind.star: GameArt('$_icons/star.png'),
  GameIconKind.stars1: GameArt('$_icons/star.png'),
  GameIconKind.bonus: GameArt('$_icons/star.png'),
  GameIconKind.newLevel: GameArt('$_icons/star.png'),
  GameIconKind.starEmpty: GameArt('$_icons/star.png', tone: GameArtTone.empty),
  GameIconKind.heart: GameArt('$_icons/heart.png'),
  GameIconKind.heartEmpty: GameArt('$_icons/heart_outline.svg'),
  GameIconKind.heartBroken: GameArt('$_icons/heart_broken.png'),
  GameIconKind.home: GameArt('$_icons/home.png'),
  GameIconKind.settings: GameArt('$_icons/settings.png'),
  GameIconKind.hint: GameArt('$_icons/hint.png'),
  GameIconKind.remove: GameArt('$_icons/booster_erase.svg'),
  GameIconKind.wand: GameArt('$_icons/booster_sweep.svg'),
  GameIconKind.ruler: GameArt('$_icons/booster_ruler.svg'),
  GameIconKind.levelLocked: GameArt('$_icons/lock.png'),
  GameIconKind.musicOn: GameArt('$_icons/music.png'),
  GameIconKind.musicOff: GameArt('$_icons/music.png', tone: GameArtTone.dim),
  GameIconKind.trophy: GameArt('$_icons/trophy.png'),
  GameIconKind.levelComplete: GameArt('$_icons/trophy.png'),
  GameIconKind.achievement: GameArt('$_icons/medal.png'),
  GameIconKind.medal: GameArt('$_icons/medal.png'),
  GameIconKind.shop: GameArt('$_icons/sack.png'),
  GameIconKind.coinBundle: GameArt('$_icons/sack.png'),
  GameIconKind.gift: GameArt('$_icons/gift.png'),
  GameIconKind.freeGift: GameArt('$_icons/gift.png'),
  GameIconKind.freeReward: GameArt('$_icons/gift.png'),
  GameIconKind.claimReward: GameArt('$_icons/gift.png'),
  GameIconKind.starterPack: GameArt('$_icons/gift.png'),
  GameIconKind.chest: GameArt('$_icons/chest.png'),
  GameIconKind.chestOpen: GameArt('$_icons/chest_open.png'),
  GameIconKind.giftOpen: GameArt('$_icons/chest_open.png'),
  GameIconKind.watchAd: GameArt('$_icons/tv.png'),
  GameIconKind.rewardedAd: GameArt('$_icons/tv.png'),
  GameIconKind.removeAds: GameArt('$_icons/remove_ads.png'),
  GameIconKind.noAds: GameArt('$_icons/remove_ads.png'),
  GameIconKind.adFree: GameArt('$_icons/remove_ads.png'),
  GameIconKind.progress: GameArt('$_icons/xp.png'),
  GameIconKind.haptic: GameArt('$_icons/thunder.png'),
  GameIconKind.calendar: GameArt('$_icons/calendar.png'),
  GameIconKind.dailyReward: GameArt('$_icons/calendar.png'),
  GameIconKind.album: GameArt('$_icons/book.png'),
  GameIconKind.crown: GameArt('$_icons/crown.png'),
  GameIconKind.grid: GameArt('$_icons/map.png'),
  GameIconKind.refresh: GameArt('$_icons/refresh.png'),
  GameIconKind.reset: GameArt('$_icons/refresh.png'),
  GameIconKind.restart: GameArt('$_icons/replay.png'),
  GameIconKind.pause: GameArt('$_icons/pause.png'),
  GameIconKind.play: GameArt('$_icons/play.png'),
  GameIconKind.continuePlay: GameArt('$_icons/play.png'),
  GameIconKind.info: GameArt('$_icons/info.png'),
  GameIconKind.wheel: GameArt('$_icons/event_ticket.svg'),
};

/// Semantic names used by the game. Each one points at a single [GameIconKind].
class GameAssets {
  GameAssets._();

  static const coin = GameIconKind.coin;
  static const coinStack = GameIconKind.coinStack;
  static const star = GameIconKind.star;
  static const starEmpty = GameIconKind.starEmpty;
  static const heart = GameIconKind.heart;
  static const heartEmpty = GameIconKind.heartEmpty;
  static const crown = GameIconKind.crown;
  static const flame = GameIconKind.streak;
  static const home = GameIconKind.home;
  static const settings = GameIconKind.settings;
  static const daily = GameIconKind.calendar;
  static const info = GameIconKind.info;
  static const shop = GameIconKind.shop;
  static const wheel = GameIconKind.wheel;
  static const album = GameIconKind.album;
  static const awards = GameIconKind.medal;
  static const hint = GameIconKind.hint;
  static const eraser = GameIconKind.remove;
  static const magicWand = GameIconKind.wand;
  static const ruler = GameIconKind.ruler;
  static const lock = GameIconKind.levelLocked;
  static const play = GameIconKind.play;
  static const back = GameIconKind.back;
  static const restart = GameIconKind.restart;
  static const soundOn = GameIconKind.soundOn;
  static const soundOff = GameIconKind.soundOff;
  static const musicOn = GameIconKind.musicOn;
  static const musicOff = GameIconKind.musicOff;
  static const vibration = GameIconKind.haptic;
}
