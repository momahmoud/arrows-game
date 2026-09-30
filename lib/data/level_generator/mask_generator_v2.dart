import 'dart:math';

import '../../core/constants.dart';
import 'bitmap_animal_templates.dart';

/// V2 Parametric mask generator for puzzle canvas shapes.
///
/// Expanded from V1:
///   Boss: 34 shapes total (14 original + 20 new geometric/angular)
///   God:  24 shapes total ( 6 original + 18 new decorative/pictorial)
///
/// ALL shapes use pure-math primitives (_rect, _ellipse, _triangle, _polygon).
/// No images, no SVG assets required.
///
/// Shape name lists (bossShapeNames, godShapeNames) are exposed so the
/// no-repeat history logic in LevelGeneratorV2 can operate on them.
class MaskGeneratorV2 {
  MaskGeneratorV2._();

  // ── Shape name pools — used by LevelGeneratorV2 for the no-repeat rule ────

  /// Normal levels rotate through these in order. Each fills roughly as much
  /// of the grid as the old long rectangle did, so difficulty stays put.
  static const List<String> normalShapeNames = [
    'circle', 'diamond', 'hexagon', 'octagon', 'pentagon', 'plus', 'heart',
  ];

  static const List<String> bossShapeNames = [
    'cat', 'dog', 'frog', 'fox', 'tiger', 'panda',
    'fish', 'bird', 'butterfly', 'guitar', 'tree',
    'owl', 'camel', 'lion', 'elephant', 'rabbit', 'duck',
    'scorpion', 'horse', 'wolf', 'bear', 'pig', 'bee', 'snake',
    'whale', 'dolphin', 'crab', 'penguin', 'cow', 'sheep',
    'eagle', 'parrot', 'mouse', 'falcon', 'seaTurtle',
    'gorilla', 'gecko', 'chick', 'androidBot', 'yarnCluster', 'apple',
    'giraffe', 'zebra', 'deer', 'kangaroo', 'hippo', 'rhino', 'monkey',
    'leopard', 'dinosaur', 'trex', 'dragon', 'octopus', 'shark', 'squid',
    'lobster', 'tropicalFish', 'blowfish', 'seal', 'peacock', 'swan',
    'rooster', 'turkey', 'dove', 'dodo', 'bat', 'hedgehog', 'squirrel',
    'sloth', 'otter', 'llama', 'goat', 'bison', 'mammoth', 'poodle', 'ant',
    'ladybug', 'snail', 'spider', 'cactus', 'mushroom', 'pear',
    'strawberry', 'pineapple', 'banana', 'carrot', 'grapes', 'mapleLeaf',
    'clover', 'tulip', 'sunflower', 'cupcake', 'teapot', 'trophy', 'bell',
    'airplane', 'car', 'sailboat', 'balloon', 'lightBulb', 'ghost',
    'spaceInvader',
    'unicorn', 'mermaid', 'fairy', 'genie', 'wizard', 'ninja', 'ufo',
    'phoenix', 'statueOfLiberty', 'circusTent', 'carouselHorse', 'volcano',
    'helicopter', 'locomotive', 'motorcycle', 'skateboard', 'saxophone',
    'trumpet', 'drum', 'microphone', 'headphones', 'joystick',
    'puzzlePiece', 'chessPawn', 'hourglass', 'alarmClock', 'telescope',
    'diyaLamp', 'kite', 'jellyfish', 'moose', 'goose', 'lotus', 'coral',
    'tornado', 'fire', 'snowman', 'thumbsUp', 'peaceHand', 'pizza', 'donut',
    'croissant', 'birthdayCake', 'sneaker', 'highHeel', 'topHat', 'dress',
    'fly', 'worm', 'caterpillar', 'orangutan', 'skunk', 'raccoon', 'badger',
    'beaver', 'guideDog', 'hatchingChick', 'crocodile', 'bactrianCamel',
    'waterBuffalo', 'ox', 'ram', 'rat', 'catFace', 'donkey', 'crowBird',
    'feather', 'nest', 'wing', 'sled', 'iceSkate', 'bowling', 'medal',
    'yoyo', 'nestingDolls', 'scissors', 'axe', 'wrench', 'magnet',
    'testTube', 'microscope', 'satellite', 'banjo', 'accordion', 'bone',
    'tooth', 'flexedBiceps', 'wavingHand', 'loveYouHand', 'tshirt', 'cap',
    'graduationCap', 'boot', 'ring', 'stormCloud', 'wave',
    'classicalBuilding', 'tent', 'fountain', 'tractor', 'racingCar',
    'canoe', 'ship', 'coffee', 'lemon', 'broccoli', 'corn', 'hotPepper',
    'garlic', 'poultryLeg', 'candy', 'honeyPot', 'pretzel',
    'house', 'crown', 'saturn',
    'trapezoid', 'parallelogram', 'pentagon', 'octagon',
    'gear', 'star4', 'shield', 'castle',
  ];

  static const List<String> godShapeNames = [
    'heart', 'star', 'diamond', 'hexagon', 'blob', 'circle',
    'flower', 'giftBox', 'shield', 'rocket', 'sun', 'cloud',
    'gem', 'snowflake', 'teddyBear', 'globe', 'cat', 'crown', 'castle',
    'palmTree', 'dallah', 'falcon', 'fanoos', 'dates', 'minaret', 'dhow',
    'seaTurtle', 'eagle', 'whale', 'lion', 'owl', 'dolphin', 'penguin',
    'peacock', 'dragon', 'octopus', 'butterfly', 'swan', 'giraffe', 'dove',
    'sunflower', 'mapleLeaf',
    'unicorn', 'mermaid', 'phoenix', 'genie', 'fairy', 'wizard',
    'statueOfLiberty', 'carouselHorse', 'lotus', 'diyaLamp', 'jellyfish',
    'ufo',
    'bactrianCamel', 'crowBird', 'feather', 'wing', 'nestingDolls',
    'classicalBuilding', 'ship', 'coffee', 'tent', 'pretzel',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  static Set<String> maskForLevelType(LevelType type, Random rng, int side) {
    switch (type) {
      case LevelType.tutorial:
        return squareMask(side);
      case LevelType.normal:
        return shapeByName(
            normalShapeNames[rng.nextInt(normalShapeNames.length)], side, rng);
      case LevelType.boss:
        final mask = _randomBossShape(side, rng);
        final minCells = (side * side * 0.60).floor();
        final selected = mask.length >= minCells ? mask : circleMask(side);
        return _ensureMinBBox(selected, side);
      case LevelType.god:
        final mask = _randomGodShape(side, rng);
        final minCells = (side * side * 0.65).floor();
        final selected = mask.length >= minCells ? mask : circleMask(side);
        return _ensureMinBBox(selected, side);
    }
  }

  static Set<String> _ensureMinBBox(Set<String> mask, int side) {
    final targetBBox = min(side - 2, 27);
    int minR = 999, maxR = -1, minC = 999, maxC = -1;
    for (final cell in mask) {
      final parts = cell.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    final w = maxC - minC + 1;
    final h = maxR - minR + 1;
    if (w >= targetBBox && h >= targetBBox) return mask;
    return squareMask(side);
  }

  static Set<String> _randomBossShape(int side, Random rng) {
    final name = bossShapeNames[rng.nextInt(bossShapeNames.length)];
    return shapeByName(name, side, rng);
  }

  static Set<String> _randomGodShape(int side, Random rng) {
    final name = godShapeNames[rng.nextInt(godShapeNames.length)];
    return shapeByName(name, side, rng);
  }

  // ── Shape by name ──────────────────────────────────────────────────────────

  static Set<String> shapeByName(String name, int side, Random rng) {
    switch (name) {
      case 'square':        return squareMask(side);
      case 'longRectangle': return longRectangleMask(side);
      // ── Original V1 shapes ────────────────────────────────────────────────
      case 'cat':         return catMask(side);
      case 'dog':         return dogMask(side);
      case 'frog':        return frogMask(side);
      case 'fox':         return foxMask(side);
      case 'tiger':       return tigerMask(side);
      case 'panda':       return pandaMask(side);
      case 'fish':        return fishMask(side);
      case 'bird':        return birdMask(side);
      case 'butterfly':   return butterflyMask(side);
      case 'guitar':      return guitarMask(side);
      case 'tree':        return treeMask(side);
      case 'house':       return houseMask(side);
      case 'crown':       return crownMask(side);
      case 'castle':      return castleMask(side);
      case 'saturn':      return saturnMask(side);
      case 'heart':       return heartMask(side);
      case 'star':        return starMask(side, 5);
      case 'diamond':     return diamondMask(side);
      case 'hexagon':     return hexagonMask(side);
      case 'blob':        return blobMask(side, rng.nextInt(9999));
      case 'circle':      return circleMask(side);

      // ── V2 Boss shapes ─────────────────────────────────────────────────────
      case 'plus':           return plusMask(side);
      case 'tShape':         return tShapeMask(side);
      case 'lShape':         return lShapeMask(side);
      case 'hShape':         return hShapeMask(side);
      case 'uShape':         return uShapeMask(side);
      case 'zShape':         return zShapeMask(side);
      case 'xCross':         return xCrossMask(side);
      case 'arrowUp':        return arrowUpMask(side);
      case 'arrowRight':     return arrowRightMask(side);
      case 'chevron':        return chevronMask(side);
      case 'staircase':      return staircaseMask(side);
      case 'trapezoid':      return trapezoidMask(side);
      case 'parallelogram':  return parallelogramMask(side);
      case 'pentagon':       return pentagonMask(side);
      case 'octagon':        return octagonMask(side);
      case 'pinwheel':       return pinwheelMask(side);
      case 'gear':           return gearMask(side);
      case 'lightningBolt':  return lightningBoltMask(side);
      case 'star4':          return starMask(side, 4);
      case 'ribbon':         return ribbonMask(side);

      // ── V2 God shapes ──────────────────────────────────────────────────────
      case 'flower':         return flowerMask(side);
      case 'spinningTop':    return spinningTopMask(side);
      case 'lollipop':       return lollipopMask(side);
      case 'iceCream':       return iceCreamMask(side);
      case 'crescentMoon':   return crescentMoonMask(side);
      case 'giftBox':        return giftBoxMask(side);
      case 'anchor':         return anchorMask(side);
      case 'shield':         return shieldMask(side);
      case 'rocket':         return rocketMask(side);
      case 'sun':            return sunMask(side);
      case 'cloud':          return cloudMask(side);
      case 'umbrella':       return umbrellaMask(side);
      case 'key':            return keyMask(side);
      case 'bowtie':         return bowtieMask(side);
      case 'gem':            return gemMask(side);
      case 'snowflake':      return snowflakeMask(side);
      case 'teddyBear':      return teddyBearMask(side);
      case 'globe':          return globeMask(side);
      case 'palmTree':       return palmTreeMask(side);
      case 'dallah':         return dallahMask(side);
      case 'falcon':         return falconMask(side);
      case 'fanoos':         return fanoosMask(side);
      case 'dates':          return datesMask(side);
      case 'minaret':        return minaretMask(side);
      case 'dhow':           return dhowMask(side);
      case 'seaTurtle':      return seaTurtleMask(side);
      case 'owl':            return owlMask(side);
      case 'camel':          return camelMask(side);
      case 'lion':           return lionMask(side);
      case 'elephant':       return elephantMask(side);
      case 'rabbit':         return rabbitMask(side);
      case 'duck':           return duckMask(side);
      case 'scorpion':       return scorpionMask(side);
      case 'horse':          return horseMask(side);
      case 'wolf':           return wolfMask(side);
      case 'bear':           return bearMask(side);
      case 'pig':            return pigMask(side);
      case 'bee':            return beeMask(side);
      case 'snake':          return snakeMask(side);
      case 'whale':          return whaleMask(side);
      case 'dolphin':        return dolphinMask(side);
      case 'crab':           return crabMask(side);
      case 'penguin':        return penguinMask(side);
      case 'cow':            return cowMask(side);
      case 'sheep':          return sheepMask(side);
      case 'eagle':          return eagleMask(side);
      case 'parrot':         return parrotMask(side);
      case 'mouse':          return mouseMask(side);
      case 'gorilla':        return gorillaMask(side);
      case 'gecko':          return geckoMask(side);
      case 'chick':          return chickMask(side);
      case 'androidBot':     return androidBotMask(side);
      case 'yarnCluster':    return yarnClusterMask(side);
      case 'apple':          return appleMask(side);
      case 'giraffe':     return giraffeMask(side);
      case 'zebra':       return zebraMask(side);
      case 'deer':        return deerMask(side);
      case 'kangaroo':    return kangarooMask(side);
      case 'hippo':       return hippoMask(side);
      case 'rhino':       return rhinoMask(side);
      case 'monkey':      return monkeyMask(side);
      case 'leopard':     return leopardMask(side);
      case 'dinosaur':    return dinosaurMask(side);
      case 'trex':        return trexMask(side);
      case 'dragon':      return dragonMask(side);
      case 'octopus':     return octopusMask(side);
      case 'shark':       return sharkMask(side);
      case 'squid':       return squidMask(side);
      case 'lobster':     return lobsterMask(side);
      case 'tropicalFish': return tropicalFishMask(side);
      case 'blowfish':    return blowfishMask(side);
      case 'seal':        return sealMask(side);
      case 'peacock':     return peacockMask(side);
      case 'swan':        return swanMask(side);
      case 'rooster':     return roosterMask(side);
      case 'turkey':      return turkeyMask(side);
      case 'dove':        return doveMask(side);
      case 'dodo':        return dodoMask(side);
      case 'bat':         return batMask(side);
      case 'hedgehog':    return hedgehogMask(side);
      case 'squirrel':    return squirrelMask(side);
      case 'sloth':       return slothMask(side);
      case 'otter':       return otterMask(side);
      case 'llama':       return llamaMask(side);
      case 'goat':        return goatMask(side);
      case 'bison':       return bisonMask(side);
      case 'mammoth':     return mammothMask(side);
      case 'poodle':      return poodleMask(side);
      case 'ant':         return antMask(side);
      case 'ladybug':     return ladybugMask(side);
      case 'snail':       return snailMask(side);
      case 'spider':      return spiderMask(side);
      case 'cactus':      return cactusMask(side);
      case 'mushroom':    return mushroomMask(side);
      case 'pear':        return pearMask(side);
      case 'strawberry':  return strawberryMask(side);
      case 'pineapple':   return pineappleMask(side);
      case 'banana':      return bananaMask(side);
      case 'carrot':      return carrotMask(side);
      case 'grapes':      return grapesMask(side);
      case 'mapleLeaf':   return mapleLeafMask(side);
      case 'clover':      return cloverMask(side);
      case 'tulip':       return tulipMask(side);
      case 'sunflower':   return sunflowerMask(side);
      case 'cupcake':     return cupcakeMask(side);
      case 'teapot':      return teapotMask(side);
      case 'trophy':      return trophyMask(side);
      case 'bell':        return bellMask(side);
      case 'airplane':    return airplaneMask(side);
      case 'car':         return carMask(side);
      case 'sailboat':    return sailboatMask(side);
      case 'balloon':     return balloonMask(side);
      case 'lightBulb':   return lightBulbMask(side);
      case 'ghost':       return ghostMask(side);
      case 'spaceInvader': return spaceInvaderMask(side);
      case 'unicorn':     return unicornMask(side);
      case 'mermaid':     return mermaidMask(side);
      case 'fairy':       return fairyMask(side);
      case 'genie':       return genieMask(side);
      case 'wizard':      return wizardMask(side);
      case 'ninja':       return ninjaMask(side);
      case 'ufo':         return ufoMask(side);
      case 'phoenix':     return phoenixMask(side);
      case 'statueOfLiberty': return statueOfLibertyMask(side);
      case 'circusTent':  return circusTentMask(side);
      case 'carouselHorse': return carouselHorseMask(side);
      case 'volcano':     return volcanoMask(side);
      case 'helicopter':  return helicopterMask(side);
      case 'locomotive':  return locomotiveMask(side);
      case 'motorcycle':  return motorcycleMask(side);
      case 'skateboard':  return skateboardMask(side);
      case 'saxophone':   return saxophoneMask(side);
      case 'trumpet':     return trumpetMask(side);
      case 'drum':        return drumMask(side);
      case 'microphone':  return microphoneMask(side);
      case 'headphones':  return headphonesMask(side);
      case 'joystick':    return joystickMask(side);
      case 'puzzlePiece': return puzzlePieceMask(side);
      case 'chessPawn':   return chessPawnMask(side);
      case 'hourglass':   return hourglassMask(side);
      case 'alarmClock':  return alarmClockMask(side);
      case 'telescope':   return telescopeMask(side);
      case 'diyaLamp':    return diyaLampMask(side);
      case 'kite':        return kiteMask(side);
      case 'jellyfish':   return jellyfishMask(side);
      case 'moose':       return mooseMask(side);
      case 'goose':       return gooseMask(side);
      case 'lotus':       return lotusMask(side);
      case 'coral':       return coralMask(side);
      case 'tornado':     return tornadoMask(side);
      case 'fire':        return fireMask(side);
      case 'snowman':     return snowmanMask(side);
      case 'thumbsUp':    return thumbsUpMask(side);
      case 'peaceHand':   return peaceHandMask(side);
      case 'pizza':       return pizzaMask(side);
      case 'donut':       return donutMask(side);
      case 'croissant':   return croissantMask(side);
      case 'birthdayCake': return birthdayCakeMask(side);
      case 'sneaker':     return sneakerMask(side);
      case 'highHeel':    return highHeelMask(side);
      case 'topHat':      return topHatMask(side);
      case 'dress':       return dressMask(side);
      case 'fly':         return flyMask(side);
      case 'worm':        return wormMask(side);
      case 'caterpillar': return caterpillarMask(side);
      case 'orangutan':   return orangutanMask(side);
      case 'skunk':       return skunkMask(side);
      case 'raccoon':     return raccoonMask(side);
      case 'badger':      return badgerMask(side);
      case 'beaver':      return beaverMask(side);
      case 'guideDog':    return guideDogMask(side);
      case 'hatchingChick': return hatchingChickMask(side);
      case 'crocodile':   return crocodileMask(side);
      case 'bactrianCamel': return bactrianCamelMask(side);
      case 'waterBuffalo': return waterBuffaloMask(side);
      case 'ox':          return oxMask(side);
      case 'ram':         return ramMask(side);
      case 'rat':         return ratMask(side);
      case 'catFace':     return catFaceMask(side);
      case 'donkey':      return donkeyMask(side);
      case 'crowBird':    return crowBirdMask(side);
      case 'feather':     return featherMask(side);
      case 'nest':        return nestMask(side);
      case 'wing':        return wingMask(side);
      case 'sled':        return sledMask(side);
      case 'iceSkate':    return iceSkateMask(side);
      case 'bowling':     return bowlingMask(side);
      case 'medal':       return medalMask(side);
      case 'yoyo':        return yoyoMask(side);
      case 'nestingDolls': return nestingDollsMask(side);
      case 'scissors':    return scissorsMask(side);
      case 'axe':         return axeMask(side);
      case 'wrench':      return wrenchMask(side);
      case 'magnet':      return magnetMask(side);
      case 'testTube':    return testTubeMask(side);
      case 'microscope':  return microscopeMask(side);
      case 'satellite':   return satelliteMask(side);
      case 'banjo':       return banjoMask(side);
      case 'accordion':   return accordionMask(side);
      case 'bone':        return boneMask(side);
      case 'tooth':       return toothMask(side);
      case 'flexedBiceps': return flexedBicepsMask(side);
      case 'wavingHand':  return wavingHandMask(side);
      case 'loveYouHand': return loveYouHandMask(side);
      case 'tshirt':      return tshirtMask(side);
      case 'cap':         return capMask(side);
      case 'graduationCap': return graduationCapMask(side);
      case 'boot':        return bootMask(side);
      case 'ring':        return ringMask(side);
      case 'stormCloud':  return stormCloudMask(side);
      case 'wave':        return waveMask(side);
      case 'classicalBuilding': return classicalBuildingMask(side);
      case 'tent':        return tentMask(side);
      case 'fountain':    return fountainMask(side);
      case 'tractor':     return tractorMask(side);
      case 'racingCar':   return racingCarMask(side);
      case 'canoe':       return canoeMask(side);
      case 'ship':        return shipMask(side);
      case 'coffee':      return coffeeMask(side);
      case 'lemon':       return lemonMask(side);
      case 'broccoli':    return broccoliMask(side);
      case 'corn':        return cornMask(side);
      case 'hotPepper':   return hotPepperMask(side);
      case 'garlic':      return garlicMask(side);
      case 'poultryLeg':  return poultryLegMask(side);
      case 'candy':       return candyMask(side);
      case 'honeyPot':    return honeyPotMask(side);
      case 'pretzel':     return pretzelMask(side);

      default: return squareMask(side);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  GEOMETRIC PRIMITIVES
  // ═══════════════════════════════════════════════════════════════════════════

  static Set<String> squareMask(int side) {
    final mask = <String>{};
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) mask.add('$r,$c');
    }
    return mask;
  }

  /// Long vertical rectangle mask for normal levels (13:19 width-to-height ratio).
  /// For a grid side of S rows, target width is ~ S * (13/19) columns.
  static Set<String> longRectangleMask(int side) {
    final mask = <String>{};
    final activeCols = (side * 13 / 19).round().clamp(1, side);
    final colMargin = ((side - activeCols) / 2).floor().clamp(0, side ~/ 2);
    for (int r = 0; r < side; r++) {
      for (int c = colMargin; c < colMargin + activeCols; c++) {
        mask.add('$r,$c');
      }
    }
    return mask;
  }

  static void _ellipse(Set<String> mask, int side,
      double cx, double cy, double rx, double ry) {
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final dx = (c + 0.5 - cx) / rx, dy = (r + 0.5 - cy) / ry;
        if (dx * dx + dy * dy <= 1.0) mask.add('$r,$c');
      }
    }
  }

  static void _rect(Set<String> mask, int side,
      double x1, double y1, double x2, double y2) {
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final px = c + 0.5, py = r + 0.5;
        if (px >= x1 && px <= x2 && py >= y1 && py <= y2) mask.add('$r,$c');
      }
    }
  }

  static void _triangle(Set<String> mask, int side,
      double ax, double ay, double bx, double by, double cx2, double cy2) {
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final px = c + 0.5, py = r + 0.5;
        final d1 = _cross(px, py, ax, ay, bx, by);
        final d2 = _cross(px, py, bx, by, cx2, cy2);
        final d3 = _cross(px, py, cx2, cy2, ax, ay);
        final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
        final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
        if (!(hasNeg && hasPos)) mask.add('$r,$c');
      }
    }
  }

  static double _cross(double px, double py,
      double ax, double ay, double bx, double by) =>
      (px - bx) * (ay - by) - (ax - bx) * (py - by);

  /// General N-sided convex polygon via point-in-polygon.
  static void _polygon(Set<String> mask, int side, List<List<double>> verts) {
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final px = c + 0.5, py = r + 0.5;
        if (_pointInPolygon(px, py, verts)) mask.add('$r,$c');
      }
    }
  }

  static bool _pointInPolygon(double px, double py, List<List<double>> verts) {
    bool inside = false;
    final n = verts.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = verts[i][0], yi = verts[i][1];
      final xj = verts[j][0], yj = verts[j][1];
      if (((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Subtract [remove] cells from [base].
  static Set<String> _subtract(Set<String> base, Set<String> remove) =>
      base.difference(remove);

  /// Keep only the largest connected region.
  static Set<String> _clean(Set<String> mask, int side) {
    if (mask.isEmpty) return mask;
    final visited = <String>{};
    final regions = <Set<String>>[];
    for (final cell in mask) {
      if (visited.contains(cell)) continue;
      final region = <String>{};
      final stack  = [cell];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        if (!mask.contains(cur) || visited.contains(cur)) continue;
        visited.add(cur); region.add(cur);
        final p = cur.split(',');
        final r = int.parse(p[0]), c = int.parse(p[1]);
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nk = '${r+d[0]},${c+d[1]}';
          if (mask.contains(nk) && !visited.contains(nk)) stack.add(nk);
        }
      }
      if (region.isNotEmpty) regions.add(region);
    }
    if (regions.isEmpty) return mask;
    regions.sort((a, b) => b.length.compareTo(a.length));
    return regions.first;
  }

  /// Resamples a `#`/`.` template onto a [side]×[side] cell mask.
  /// Trims empty margin, then scales uniformly (centered) so wide or tall
  /// silhouettes keep their proportions instead of being stretched square.
  static Set<String> _bitmapMask(int side, List<String> template) {
    final mask = <String>{};
    final th = template.length;
    final tw = template.first.length;
    var minR = th, maxR = -1, minC = tw, maxC = -1;
    for (int r = 0; r < th; r++) {
      for (int c = 0; c < tw; c++) {
        if (template[r][c] != '#') continue;
        if (r < minR) minR = r;
        if (r > maxR) maxR = r;
        if (c < minC) minC = c;
        if (c > maxC) maxC = c;
      }
    }
    if (maxR < minR) return mask;
    final bh = maxR - minR + 1;
    final bw = maxC - minC + 1;
    final span = max(bh, bw);
    final offR = (span - bh) / 2;
    final offC = (span - bw) / 2;
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final tr = ((r + 0.5) / side * span - offR).floor();
        final tc = ((c + 0.5) / side * span - offC).floor();
        if (tr < 0 || tr >= bh || tc < 0 || tc >= bw) continue;
        if (template[minR + tr][minC + tc] == '#') mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ORIGINAL V1 SHAPES (preserved exactly)
  // ═══════════════════════════════════════════════════════════════════════════

  static Set<String> circleMask(int side) {
    final mask = <String>{};
    _ellipse(mask, side, side / 2.0, side / 2.0, side / 2.0 - 0.4, side / 2.0 - 0.4);
    return _clean(mask, side);
  }

  static Set<String> heartMask(int side) {
    final mask = <String>{};
    final s = side.toDouble();
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final x = (c + 0.5) / s * 2.0 - 1.0;
        final y = -(((r + 0.5) / s) * 2.0 - 1.0) * 0.92 + 0.04;
        final v = pow(x * x + y * y - 1, 3).toDouble() - x * x * y * y * y;
        if (v <= 0.0) mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> starMask(int side, int points) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0;
    final outerR = side / 2.0 - 0.3, innerR = outerR * 0.42;
    final step = pi / points;
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final dx = c + 0.5 - cx, dy = r + 0.5 - cy;
        final angle = atan2(dy, dx), dist = sqrt(dx * dx + dy * dy);
        final mod   = ((angle + pi) / step) % 2.0;
        final limit = mod < 1.0
            ? outerR * mod + innerR * (1 - mod)
            : outerR * (2 - mod) + innerR * (mod - 1);
        if (dist <= limit + 0.55) mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> diamondMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0, r = side / 2.0 - 0.3;
    for (int row = 0; row < side; row++) {
      for (int col = 0; col < side; col++) {
        if ((col + 0.5 - cx).abs() + (row + 0.5 - cy).abs() <= r + 0.55) {
          mask.add('$row,$col');
        }
      }
    }
    return _clean(mask, side);
  }

  static Set<String> hexagonMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0, r = side / 2.0 - 0.5;
    for (int row = 0; row < side; row++) {
      for (int col = 0; col < side; col++) {
        final dx = (col + 0.5 - cx).abs(), dy = (row + 0.5 - cy).abs();
        if (dx <= r && dy <= r * 0.866 && dx + dy * 1.155 <= r * 2.0) {
          mask.add('$row,$col');
        }
      }
    }
    return _clean(mask, side);
  }

  static Set<String> blobMask(int side, int seed) {
    final rng   = Random(seed);
    final mask  = <String>{};
    final cx = side / 2.0, cy = side / 2.0, baseR = side / 2.0 - 0.8;
    final a1 = 0.12 + rng.nextDouble() * 0.08;
    final a2 = 0.07 + rng.nextDouble() * 0.06;
    final phi1 = rng.nextDouble() * 2 * pi;
    final phi2 = rng.nextDouble() * 2 * pi;
    final f1   = (rng.nextInt(3) + 2).toDouble();
    final f2   = (rng.nextInt(4) + 5).toDouble();
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final dx = c + 0.5 - cx, dy = r + 0.5 - cy;
        final angle = atan2(dy, dx), dist = sqrt(dx * dx + dy * dy);
        final limit = baseR * (1.0 + a1 * sin(f1 * angle + phi1) + a2 * sin(f2 * angle + phi2));
        if (dist <= limit) mask.add('$r,$c');
      }
    }
    return _clean(mask, side);
  }

  static Set<String> catMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.cat32);

  static Set<String> dogMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dog32);

  static Set<String> frogMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.frog32);

  static Set<String> foxMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fox32);

  static Set<String> tigerMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tiger32);

  static Set<String> pandaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.panda32);

  static Set<String> fishMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fish32);

  static Set<String> birdMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bird32);

  static Set<String> butterflyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.butterfly32);

  static Set<String> guitarMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.5, s*0.70, s*0.30, s*0.25);
    _ellipse(mask, side, s*0.5, s*0.40, s*0.24, s*0.20);
    _rect(mask, side, s*0.43, s*0.04, s*0.57, s*0.24);
    _rect(mask, side, s*0.38, s*0.56, s*0.62, s*0.66);
    return _clean(mask, side);
  }

  static Set<String> treeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.5, s*0.38, s*0.36, s*0.34);
    _rect(mask, side, s*0.42, s*0.68, s*0.58, s*0.94);
    return _clean(mask, side);
  }

  static Set<String> houseMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.10, s*0.44, s*0.90, s*0.92);
    _triangle(mask, side, s*0.0, s*0.44, s*1.0, s*0.44, s*0.5, s*0.06);
    return _clean(mask, side);
  }

  static Set<String> crownMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.08, s*0.58, s*0.92, s*0.90);
    _triangle(mask, side, s*0.08, s*0.58, s*0.28, s*0.58, s*0.18, s*0.10);
    _triangle(mask, side, s*0.36, s*0.58, s*0.64, s*0.58, s*0.50, s*0.04);
    _triangle(mask, side, s*0.72, s*0.58, s*0.92, s*0.58, s*0.82, s*0.10);
    return _clean(mask, side);
  }

  static Set<String> saturnMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.5, s*0.5, s*0.38, s*0.38);
    _ellipse(mask, side, s*0.5, s*0.5, s*0.48, s*0.16);
    return _clean(mask, side);
  }

  static Set<String> castleMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s * 0.08, s * 0.35, s * 0.92, s * 0.94);
    _rect(mask, side, s * 0.08, s * 0.12, s * 0.30, s * 0.35);
    _rect(mask, side, s * 0.70, s * 0.12, s * 0.92, s * 0.35);
    _rect(mask, side, s * 0.38, s * 0.08, s * 0.62, s * 0.35);
    return _clean(mask, side);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  V2 BOSS SHAPES — Geometric / Angular Silhouettes
  // ═══════════════════════════════════════════════════════════════════════════

  /// + cross shape
  static Set<String> plusMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.35, s*0.05, s*0.65, s*0.95); // vertical
    _rect(mask, side, s*0.05, s*0.35, s*0.95, s*0.65); // horizontal
    return _clean(mask, side);
  }

  /// T shape (wide top bar + center stem)
  static Set<String> tShapeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.08, s*0.08, s*0.92, s*0.36); // top bar
    _rect(mask, side, s*0.40, s*0.36, s*0.60, s*0.92); // stem
    return _clean(mask, side);
  }

  /// L shape (long vertical + base)
  static Set<String> lShapeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.15, s*0.08, s*0.45, s*0.92); // vertical
    _rect(mask, side, s*0.15, s*0.72, s*0.85, s*0.92); // base
    return _clean(mask, side);
  }

  /// H shape (two verticals + crossbar)
  static Set<String> hShapeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.08, s*0.08, s*0.38, s*0.92); // left vertical
    _rect(mask, side, s*0.62, s*0.08, s*0.92, s*0.92); // right vertical
    _rect(mask, side, s*0.38, s*0.40, s*0.62, s*0.60); // crossbar
    return _clean(mask, side);
  }

  /// U shape (two sides + bottom connector)
  static Set<String> uShapeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.08, s*0.08, s*0.38, s*0.92); // left side
    _rect(mask, side, s*0.62, s*0.08, s*0.92, s*0.92); // right side
    _rect(mask, side, s*0.08, s*0.72, s*0.92, s*0.92); // bottom
    return _clean(mask, side);
  }

  /// Z shape (top-right, diagonal bridge, bottom-left)
  static Set<String> zShapeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.08, s*0.08, s*0.92, s*0.32); // top bar
    _rect(mask, side, s*0.08, s*0.68, s*0.92, s*0.92); // bottom bar
    _triangle(mask, side,               // diagonal bridge
        s*0.08, s*0.32,
        s*0.92, s*0.32,
        s*0.08, s*0.68);
    return _clean(mask, side);
  }

  /// X cross (two diagonal ellipses crossing at center)
  static Set<String> xCrossMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    // Approximate diagonals with two rotated thick rects via polygon
    final cx = s * 0.5, cy = s * 0.5;
    final hw = s * 0.14, len = s * 0.64;
    // Diagonal /
    _polygon(mask, side, [
      [cx - len, cy + hw], [cx - len, cy - hw],
      [cx + len, cy - hw], [cx + len, cy + hw],
    ]);
    // Diagonal \  (rotated 90°, same shape)
    _polygon(mask, side, [
      [cx - hw, cy - len], [cx + hw, cy - len],
      [cx + hw, cy + len], [cx - hw, cy + len],
    ]);
    // But we need the actual X (rotate ±45°) — approximate with triangles
    final mask2 = <String>{};
    _triangle(mask2, side, s*0.00, s*0.13, s*0.13, s*0.00, s*1.00, s*0.87);
    _triangle(mask2, side, s*0.87, s*1.00, s*1.00, s*0.87, s*0.13, s*0.00);
    _triangle(mask2, side, s*0.87, s*0.00, s*1.00, s*0.13, s*0.13, s*1.00);
    _triangle(mask2, side, s*0.00, s*0.87, s*0.13, s*1.00, s*1.00, s*0.13);
    return _clean(mask2, side);
  }

  /// Up-pointing arrow (triangle head + narrow rect stem)
  static Set<String> arrowUpMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _triangle(mask, side, s*0.08, s*0.52, s*0.92, s*0.52, s*0.50, s*0.06); // head
    _rect(mask, side, s*0.36, s*0.52, s*0.64, s*0.94);                      // stem
    return _clean(mask, side);
  }

  /// Right-pointing arrow
  static Set<String> arrowRightMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _triangle(mask, side, s*0.48, s*0.08, s*0.48, s*0.92, s*0.94, s*0.50); // head
    _rect(mask, side, s*0.06, s*0.36, s*0.48, s*0.64);                      // stem
    return _clean(mask, side);
  }

  /// V / chevron
  static Set<String> chevronMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _triangle(mask, side, s*0.00, s*0.30, s*0.50, s*0.80, s*0.50, s*0.50);
    _triangle(mask, side, s*0.50, s*0.50, s*0.50, s*0.80, s*1.00, s*0.30);
    _triangle(mask, side, s*0.00, s*0.80, s*0.50, s*0.30, s*0.50, s*0.08);
    _triangle(mask, side, s*0.50, s*0.08, s*0.50, s*0.30, s*1.00, s*0.80);
    return _clean(mask, side);
  }

  /// Descending staircase (step pattern)
  static Set<String> staircaseMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    const steps = 4;
    final step = 1.0 / steps;
    for (int i = 0; i < steps; i++) {
      _rect(mask, side,
          s * (i * step),          s * (i * step),
          s * ((i + 1) * step),    s * 1.0);
    }
    return _clean(mask, side);
  }

  /// Flat-top trapezoid
  static Set<String> trapezoidMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _polygon(mask, side, [
      [s*0.20, s*0.10], [s*0.80, s*0.10],
      [s*0.95, s*0.90], [s*0.05, s*0.90],
    ]);
    return _clean(mask, side);
  }

  /// Parallelogram (tilted rectangle)
  static Set<String> parallelogramMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _polygon(mask, side, [
      [s*0.25, s*0.10], [s*0.95, s*0.10],
      [s*0.75, s*0.90], [s*0.05, s*0.90],
    ]);
    return _clean(mask, side);
  }

  /// Regular pentagon
  static Set<String> pentagonMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0, r = side / 2.0 - 0.5;
    final verts = List.generate(5, (i) {
      final a = -pi / 2 + 2 * pi * i / 5;
      return [cx + r * cos(a), cy + r * sin(a)];
    });
    _polygon(mask, side, verts);
    return _clean(mask, side);
  }

  /// Regular octagon
  static Set<String> octagonMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0, r = side / 2.0 - 0.3;
    final verts = List.generate(8, (i) {
      final a = pi / 8 + 2 * pi * i / 8;
      return [cx + r * cos(a), cy + r * sin(a)];
    });
    _polygon(mask, side, verts);
    return _clean(mask, side);
  }

  /// Pinwheel (4 rectangles rotated 45° each)
  static Set<String> pinwheelMask(int side) {
    final mask  = <String>{};
    final cx    = side / 2.0, cy = side / 2.0;
    final hw    = side * 0.12, len = side * 0.45;
    for (int k = 0; k < 4; k++) {
      final angle = k * pi / 2 + pi / 8;
      final verts = [
        [cx + (len) * cos(angle) - hw * sin(angle),
         cy + (len) * sin(angle) + hw * cos(angle)],
        [cx + (len) * cos(angle) + hw * sin(angle),
         cy + (len) * sin(angle) - hw * cos(angle)],
        [cx + (-len) * cos(angle) + hw * sin(angle),
         cy + (-len) * sin(angle) - hw * cos(angle)],
        [cx + (-len) * cos(angle) - hw * sin(angle),
         cy + (-len) * sin(angle) + hw * cos(angle)],
      ];
      _polygon(mask, side, verts);
    }
    // Center circle
    _ellipse(mask, side, cx, cy, side * 0.10, side * 0.10);
    return _clean(mask, side);
  }

  /// Gear (circle with N rectangular teeth)
  static Set<String> gearMask(int side) {
    final mask  = <String>{};
    final cx    = side / 2.0, cy = side / 2.0;
    final inner = side * 0.28, outer = side * 0.42;
    final tooth = side * 0.08;
    _ellipse(mask, side, cx, cy, inner, inner);
    const teeth = 8;
    for (int k = 0; k < teeth; k++) {
      final angle = 2 * pi * k / teeth;
      final tx = cx + outer * cos(angle);
      final ty = cy + outer * sin(angle);
      final verts = [
        [tx - tooth * sin(angle) - tooth * cos(angle),
         ty + tooth * cos(angle) - tooth * sin(angle)],
        [tx + tooth * sin(angle) - tooth * cos(angle),
         ty - tooth * cos(angle) - tooth * sin(angle)],
        [tx + tooth * sin(angle) + tooth * cos(angle),
         ty - tooth * cos(angle) + tooth * sin(angle)],
        [tx - tooth * sin(angle) + tooth * cos(angle),
         ty + tooth * cos(angle) + tooth * sin(angle)],
      ];
      _polygon(mask, side, verts);
    }
    return _clean(mask, side);
  }

  /// Lightning bolt (Z-stepped polygon)
  static Set<String> lightningBoltMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _polygon(mask, side, [
      [s*0.55, s*0.04],  // top-right of head
      [s*0.20, s*0.55],  // bottom-left of head
      [s*0.50, s*0.55],  // inner notch
      [s*0.45, s*0.96],  // bottom of tail
      [s*0.80, s*0.45],  // top-right of body
      [s*0.50, s*0.45],  // inner notch
    ]);
    return _clean(mask, side);
  }

  /// Wide horizontal ribbon with tapered ends
  static Set<String> ribbonMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _polygon(mask, side, [
      [s*0.02, s*0.50],  // left point
      [s*0.20, s*0.28],  // upper-left
      [s*0.80, s*0.28],  // upper-right
      [s*0.98, s*0.50],  // right point
      [s*0.80, s*0.72],  // lower-right
      [s*0.20, s*0.72],  // lower-left
    ]);
    return _clean(mask, side);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  V2 GOD SHAPES — Decorative / Pictorial Silhouettes
  // ═══════════════════════════════════════════════════════════════════════════

  /// Flower (center circle + 6 petal ellipses)
  static Set<String> flowerMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    final cx = s * 0.5, cy = s * 0.5;
    _ellipse(mask, side, cx, cy, s*0.18, s*0.18); // center
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      _ellipse(mask, side,
          cx + s * 0.30 * cos(a), cy + s * 0.30 * sin(a),
          s*0.16, s*0.10);
    }
    return _clean(mask, side);
  }

  /// Spinning top (wide triangle on top, narrow triangle below)
  static Set<String> spinningTopMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _triangle(mask, side, s*0.02, s*0.08, s*0.98, s*0.08, s*0.50, s*0.52); // body
    _triangle(mask, side, s*0.42, s*0.52, s*0.58, s*0.52, s*0.50, s*0.94); // tip
    return _clean(mask, side);
  }

  /// Lollipop (circle + thin stick)
  static Set<String> lollipopMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.50, s*0.34, s*0.30, s*0.30);
    _rect(mask, side, s*0.46, s*0.64, s*0.54, s*0.94);
    return _clean(mask, side);
  }

  /// Ice cream cone (semi-circle on triangle)
  static Set<String> iceCreamMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.50, s*0.34, s*0.36, s*0.32);
    _triangle(mask, side, s*0.14, s*0.60, s*0.86, s*0.60, s*0.50, s*0.94);
    // Remove bottom half of ellipse to make it a scoop (keep above row 0.54)
    for (int r = 0; r < side; r++) {
      for (int c = 0; c < side; c++) {
        final key = '$r,$c';
        if (mask.contains(key) && (r + 0.5) / s > 0.58 && (r + 0.5) / s < 0.62) {
          final dx = (c + 0.5) / s - 0.50, dy = (r + 0.5) / s - 0.34;
          if (dx * dx / (0.36 * 0.36) + dy * dy / (0.32 * 0.32) <= 1.0) {
            // Keep — this is the overlap zone, cone will cover it
          }
        }
      }
    }
    return _clean(mask, side);
  }

  /// Crescent moon (large circle minus smaller offset circle)
  static Set<String> crescentMoonMask(int side) {
    final mask  = <String>{};
    final cutout = <String>{};
    final s = side.toDouble();
    _ellipse(mask,    side, s*0.48, s*0.50, s*0.40, s*0.44);
    _ellipse(cutout, side, s*0.60, s*0.46, s*0.32, s*0.36);
    return _clean(_subtract(mask, cutout), side);
  }

  /// Gift box (body rect + ribbon + bow)
  static Set<String> giftBoxMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.12, s*0.38, s*0.88, s*0.90); // box body
    _rect(mask, side, s*0.44, s*0.10, s*0.56, s*0.90); // vertical ribbon
    _rect(mask, side, s*0.12, s*0.44, s*0.88, s*0.56); // horizontal ribbon
    _ellipse(mask, side, s*0.38, s*0.20, s*0.10, s*0.14); // left bow loop
    _ellipse(mask, side, s*0.62, s*0.20, s*0.10, s*0.14); // right bow loop
    return _clean(mask, side);
  }

  /// Anchor (ring + shaft + horizontal crossbar)
  static Set<String> anchorMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.50, s*0.22, s*0.18, s*0.16); // ring (outer)
    final inner = <String>{};
    _ellipse(inner, side, s*0.50, s*0.22, s*0.10, s*0.09); // ring (inner cutout)
    mask.removeAll(inner);
    _rect(mask, side, s*0.46, s*0.22, s*0.54, s*0.88); // shaft
    _rect(mask, side, s*0.10, s*0.74, s*0.90, s*0.86); // crossbar
    _ellipse(mask, side, s*0.18, s*0.80, s*0.08, s*0.08); // left end
    _ellipse(mask, side, s*0.82, s*0.80, s*0.08, s*0.08); // right end
    return _clean(mask, side);
  }

  /// Shield (rounded rectangle body + pointed bottom)
  static Set<String> shieldMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.12, s*0.08, s*0.88, s*0.72);
    _triangle(mask, side, s*0.12, s*0.72, s*0.88, s*0.72, s*0.50, s*0.96);
    _ellipse(mask, side, s*0.22, s*0.14, s*0.10, s*0.10); // top-left round
    _ellipse(mask, side, s*0.78, s*0.14, s*0.10, s*0.10); // top-right round
    return _clean(mask, side);
  }

  /// Rocket (body + nose cone + 2 fins)
  static Set<String> rocketMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _rect(mask, side, s*0.36, s*0.28, s*0.64, s*0.82);                       // body
    _triangle(mask, side, s*0.36, s*0.28, s*0.64, s*0.28, s*0.50, s*0.06);  // nose
    _triangle(mask, side, s*0.14, s*0.68, s*0.36, s*0.68, s*0.36, s*0.90);  // left fin
    _triangle(mask, side, s*0.64, s*0.68, s*0.86, s*0.68, s*0.64, s*0.90);  // right fin
    return _clean(mask, side);
  }

  /// Sun (circle + 8 rectangular rays)
  static Set<String> sunMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    final cx = s * 0.5, cy = s * 0.5;
    _ellipse(mask, side, cx, cy, s*0.22, s*0.22); // center
    for (int i = 0; i < 8; i++) {
      final a  = i * pi / 4;
      final tx = cx + s * 0.38 * cos(a), ty = cy + s * 0.38 * sin(a);
      final hw = s * 0.05;
      _polygon(mask, side, [
        [tx - hw * sin(a) - s*0.08 * cos(a), ty + hw * cos(a) - s*0.08 * sin(a)],
        [tx + hw * sin(a) - s*0.08 * cos(a), ty - hw * cos(a) - s*0.08 * sin(a)],
        [tx + hw * sin(a) + s*0.08 * cos(a), ty - hw * cos(a) + s*0.08 * sin(a)],
        [tx - hw * sin(a) + s*0.08 * cos(a), ty + hw * cos(a) + s*0.08 * sin(a)],
      ]);
    }
    return _clean(mask, side);
  }

  /// Cloud (4 overlapping circles)
  static Set<String> cloudMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.30, s*0.52, s*0.22, s*0.20); // left puff
    _ellipse(mask, side, s*0.50, s*0.42, s*0.26, s*0.24); // center puff
    _ellipse(mask, side, s*0.70, s*0.52, s*0.22, s*0.20); // right puff
    _ellipse(mask, side, s*0.46, s*0.62, s*0.40, s*0.16); // base
    return _clean(mask, side);
  }

  /// Umbrella (large semicircle + handle)
  static Set<String> umbrellaMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    // Top semicircle (full ellipse, then remove bottom half)
    final dome = <String>{};
    _ellipse(dome, side, s*0.50, s*0.40, s*0.44, s*0.36);
    for (final k in dome) {
      final p = k.split(',');
      if ((int.parse(p[0]) + 0.5) / s < 0.42) mask.add(k);
    }
    // Spoke divisions (thin vertical strips removed — not really needed, add a center spoke)
    _rect(mask, side, s*0.48, s*0.40, s*0.52, s*0.40); // center point, tiny
    // Handle (vertical rect + curved end via ellipse)
    _rect(mask, side, s*0.47, s*0.68, s*0.53, s*0.90);
    _ellipse(mask, side, s*0.40, s*0.90, s*0.10, s*0.06);
    return _clean(mask, side);
  }

  /// Key (circle head + horizontal bar + notches)
  static Set<String> keyMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.28, s*0.50, s*0.22, s*0.22); // head
    final hole = <String>{};
    _ellipse(hole, side, s*0.28, s*0.50, s*0.11, s*0.11);
    mask.removeAll(hole); // hollow center
    _rect(mask, side, s*0.50, s*0.46, s*0.92, s*0.54); // shaft
    _rect(mask, side, s*0.72, s*0.54, s*0.80, s*0.66); // notch 1
    _rect(mask, side, s*0.84, s*0.54, s*0.92, s*0.62); // notch 2
    return _clean(mask, side);
  }

  /// Bowtie (two triangles touching at center)
  static Set<String> bowtieMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _triangle(mask, side, s*0.04, s*0.12, s*0.04, s*0.88, s*0.50, s*0.50); // left
    _triangle(mask, side, s*0.96, s*0.12, s*0.96, s*0.88, s*0.50, s*0.50); // right
    return _clean(mask, side);
  }

  /// Gem / jewel (wide top + narrow bottom)
  static Set<String> gemMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _polygon(mask, side, [
      [s*0.20, s*0.22], [s*0.80, s*0.22], // top edge
      [s*0.96, s*0.46], [s*0.50, s*0.94], // right side → bottom point
      [s*0.04, s*0.46],                    // left side
    ]);
    _rect(mask, side, s*0.20, s*0.08, s*0.80, s*0.22); // flat top
    return _clean(mask, side);
  }

  /// Snowflake (6 thin rectangles at 30° intervals)
  static Set<String> snowflakeMask(int side) {
    final mask = <String>{};
    final cx = side / 2.0, cy = side / 2.0;
    final len = side * 0.46, hw = side * 0.045;
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      _polygon(mask, side, [
        [cx - hw * sin(a) - len * cos(a), cy + hw * cos(a) - len * sin(a)],
        [cx + hw * sin(a) - len * cos(a), cy - hw * cos(a) - len * sin(a)],
        [cx + hw * sin(a) + len * cos(a), cy - hw * cos(a) + len * sin(a)],
        [cx - hw * sin(a) + len * cos(a), cy + hw * cos(a) + len * sin(a)],
      ]);
    }
    _ellipse(mask, side, cx, cy, side * 0.10, side * 0.10); // center dot
    return _clean(mask, side);
  }

  /// Teddy bear — round head + ears (reference level 620 style).
  static Set<String> teddyBearMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.teddyBear24);

  /// Palm tree — dense crown + trunk (24×24 bitmap, Siham reference silhouette).
  static const List<String> _palmTreeTemplate24 = [
    '........................',
    '........................',
    '........................',
    '........................',
    '......##.........##.....',
    '.....####.......####....',
    '....######.....######...',
    '...########...########..',
    '..##########.##########.',
    '.######################.',
    '..####################..',
    '...##################...',
    '.....##############.....',
    '.......############.....',
    '..........######........',
    '..........######........',
    '..........######........',
    '..........######........',
    '..........######........',
    '..........######........',
    '..........######........',
    '..........####..........',
    '........................',
    '........................',
  ];

  static Set<String> palmTreeMask(int side) =>
      _bitmapMask(side, _palmTreeTemplate24);

  static const List<String> _dallahTemplate24 = [
    '........................',
    '........................',
    '...........##...........',
    '..........####..........',
    '.........######.........',
    '........########........',
    '.......##########.......',
    '........########........',
    '.........######.........',
    '.......##########.......',
    '..##############........',
    '.##################.....',
    '.##################.....',
    '..##############........',
    '.......##########.......',
    '........########........',
    '.........######.........',
    '..........####..........',
    '...........##...........',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
  ];


  static const List<String> _fanoosTemplate24 = [
    '........................',
    '........................',
    '........................',
    '...........###..........',
    '..........#####.........',
    '.........#######........',
    '.........#######........',
    '........#########.......',
    '.......###########......',
    '.......##########.......',
    '.......##########.......',
    '.......###########......',
    '......#############.....',
    '......#############.....',
    '......#############.....',
    '......#############.....',
    '......#############.....',
    '.......###########......',
    '........#########.......',
    '........#########.......',
    '.......###########......',
    '........#########.......',
    '.........#######........',
    '........................',
  ];

  static const List<String> _datesTemplate24 = [
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '..........#####.........',
    '.........#######........',
    '........#########.......',
    '.......###########......',
    '......#############.....',
    '......#############.....',
    '......#############.....',
    '.......###########......',
    '........#########.......',
    '.........#######........',
    '..........#####.........',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
  ];

  static const List<String> _minaretTemplate24 = [
    '........................',
    '........................',
    '...........##...........',
    '..........####..........',
    '.........######.........',
    '........########........',
    '........########........',
    '.......##########.......',
    '......############......',
    '......############......',
    '.......##########.......',
    '........########........',
    '........########........',
    '........########........',
    '........########........',
    '........########........',
    '........########........',
    '........########........',
    '........########........',
    '.........######.........',
    '.........######.........',
    '..........####..........',
    '........................',
    '........................',
  ];

  static const List<String> _dhowTemplate24 = [
    '........................',
    '........................',
    '........................',
    '........................',
    '.......#############....',
    '........###########.....',
    '........###########.....',
    '.........#########......',
    '.........#########......',
    '..........#######.......',
    '..........#######.......',
    '...........#####........',
    '...........#####........',
    '............###.........',
    '...........####.........',
    '...........###..........',
    '......##############....',
    '......##############....',
    '......##############....',
    '......##############....',
    '........................',
    '........................',
    '........................',
    '........................',
  ];

  static Set<String> dallahMask(int side) =>
      _bitmapMask(side, _dallahTemplate24);
  static Set<String> falconMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.falcon32);
  static Set<String> fanoosMask(int side) =>
      _bitmapMask(side, _fanoosTemplate24);
  static Set<String> datesMask(int side) =>
      _bitmapMask(side, _datesTemplate24);
  static Set<String> minaretMask(int side) =>
      _bitmapMask(side, _minaretTemplate24);
  static Set<String> dhowMask(int side) =>
      _bitmapMask(side, _dhowTemplate24);


  static Set<String> seaTurtleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.seaTurtle32);

  static Set<String> owlMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.owl32);
  static Set<String> camelMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.camel32);
  static Set<String> lionMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.lion32);
  static Set<String> elephantMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.elephant32);
  static Set<String> rabbitMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.rabbit32);
  static Set<String> duckMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.duck32);
  static Set<String> scorpionMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.scorpion32);
  static Set<String> horseMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.horse32);
  static Set<String> wolfMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wolf32);
  static Set<String> bearMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bear32);
  static Set<String> pigMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.pig32);
  static Set<String> beeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bee32);
  static Set<String> snakeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.snake32);
  static Set<String> whaleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.whale32);
  static Set<String> dolphinMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dolphin32);
  static Set<String> crabMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.crab32);
  static Set<String> penguinMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.penguin32);
  static Set<String> cowMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.cow32);
  static Set<String> sheepMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sheep32);
  static Set<String> eagleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.eagle32);
  static Set<String> parrotMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.parrot32);
  static Set<String> mouseMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.mouse32);
  static Set<String> gorillaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.gorilla32);
  static Set<String> geckoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.gecko32);
  static Set<String> chickMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.chick32);
  static Set<String> androidBotMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.androidBot24);
  static Set<String> yarnClusterMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.yarnCluster24);
  static Set<String> appleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.apple24);
  static Set<String> giraffeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.giraffe32);
  static Set<String> zebraMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.zebra32);
  static Set<String> deerMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.deer32);
  static Set<String> kangarooMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.kangaroo32);
  static Set<String> hippoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.hippo32);
  static Set<String> rhinoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.rhino32);
  static Set<String> monkeyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.monkey32);
  static Set<String> leopardMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.leopard32);
  static Set<String> dinosaurMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dinosaur32);
  static Set<String> trexMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.trex32);
  static Set<String> dragonMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dragon32);
  static Set<String> octopusMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.octopus32);
  static Set<String> sharkMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.shark32);
  static Set<String> squidMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.squid32);
  static Set<String> lobsterMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.lobster32);
  static Set<String> tropicalFishMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tropicalFish32);
  static Set<String> blowfishMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.blowfish32);
  static Set<String> sealMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.seal32);
  static Set<String> peacockMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.peacock32);
  static Set<String> swanMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.swan32);
  static Set<String> roosterMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.rooster32);
  static Set<String> turkeyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.turkey32);
  static Set<String> doveMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dove32);
  static Set<String> dodoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dodo32);
  static Set<String> batMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bat32);
  static Set<String> hedgehogMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.hedgehog32);
  static Set<String> squirrelMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.squirrel32);
  static Set<String> slothMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sloth32);
  static Set<String> otterMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.otter32);
  static Set<String> llamaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.llama32);
  static Set<String> goatMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.goat32);
  static Set<String> bisonMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bison32);
  static Set<String> mammothMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.mammoth32);
  static Set<String> poodleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.poodle32);
  static Set<String> antMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ant32);
  static Set<String> ladybugMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ladybug32);
  static Set<String> snailMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.snail32);
  static Set<String> spiderMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.spider32);
  static Set<String> cactusMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.cactus32);
  static Set<String> mushroomMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.mushroom32);
  static Set<String> pearMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.pear32);
  static Set<String> strawberryMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.strawberry32);
  static Set<String> pineappleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.pineapple32);
  static Set<String> bananaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.banana32);
  static Set<String> carrotMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.carrot32);
  static Set<String> grapesMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.grapes32);
  static Set<String> mapleLeafMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.mapleLeaf32);
  static Set<String> cloverMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.clover32);
  static Set<String> tulipMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tulip32);
  static Set<String> sunflowerMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sunflower32);
  static Set<String> cupcakeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.cupcake32);
  static Set<String> teapotMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.teapot32);
  static Set<String> trophyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.trophy32);
  static Set<String> bellMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bell32);
  static Set<String> airplaneMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.airplane32);
  static Set<String> carMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.car32);
  static Set<String> sailboatMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sailboat32);
  static Set<String> balloonMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.balloon32);
  static Set<String> lightBulbMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.lightBulb32);
  static Set<String> ghostMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ghost32);
  static Set<String> spaceInvaderMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.spaceInvader32);
  static Set<String> unicornMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.unicorn32);
  static Set<String> mermaidMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.mermaid32);
  static Set<String> fairyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fairy32);
  static Set<String> genieMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.genie32);
  static Set<String> wizardMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wizard32);
  static Set<String> ninjaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ninja32);
  static Set<String> ufoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ufo32);
  static Set<String> phoenixMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.phoenix32);
  static Set<String> statueOfLibertyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.statueOfLiberty32);
  static Set<String> circusTentMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.circusTent32);
  static Set<String> carouselHorseMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.carouselHorse32);
  static Set<String> volcanoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.volcano32);
  static Set<String> helicopterMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.helicopter32);
  static Set<String> locomotiveMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.locomotive32);
  static Set<String> motorcycleMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.motorcycle32);
  static Set<String> skateboardMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.skateboard32);
  static Set<String> saxophoneMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.saxophone32);
  static Set<String> trumpetMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.trumpet32);
  static Set<String> drumMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.drum32);
  static Set<String> microphoneMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.microphone32);
  static Set<String> headphonesMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.headphones32);
  static Set<String> joystickMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.joystick32);
  static Set<String> puzzlePieceMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.puzzlePiece32);
  static Set<String> chessPawnMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.chessPawn32);
  static Set<String> hourglassMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.hourglass32);
  static Set<String> alarmClockMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.alarmClock32);
  static Set<String> telescopeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.telescope32);
  static Set<String> diyaLampMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.diyaLamp32);
  static Set<String> kiteMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.kite32);
  static Set<String> jellyfishMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.jellyfish32);
  static Set<String> mooseMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.moose32);
  static Set<String> gooseMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.goose32);
  static Set<String> lotusMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.lotus32);
  static Set<String> coralMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.coral32);
  static Set<String> tornadoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tornado32);
  static Set<String> fireMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fire32);
  static Set<String> snowmanMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.snowman32);
  static Set<String> thumbsUpMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.thumbsUp32);
  static Set<String> peaceHandMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.peaceHand32);
  static Set<String> pizzaMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.pizza32);
  static Set<String> donutMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.donut32);
  static Set<String> croissantMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.croissant32);
  static Set<String> birthdayCakeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.birthdayCake32);
  static Set<String> sneakerMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sneaker32);
  static Set<String> highHeelMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.highHeel32);
  static Set<String> topHatMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.topHat32);
  static Set<String> dressMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.dress32);
  static Set<String> flyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fly32);
  static Set<String> wormMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.worm32);
  static Set<String> caterpillarMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.caterpillar32);
  static Set<String> orangutanMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.orangutan32);
  static Set<String> skunkMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.skunk32);
  static Set<String> raccoonMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.raccoon32);
  static Set<String> badgerMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.badger32);
  static Set<String> beaverMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.beaver32);
  static Set<String> guideDogMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.guideDog32);
  static Set<String> hatchingChickMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.hatchingChick32);
  static Set<String> crocodileMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.crocodile32);
  static Set<String> bactrianCamelMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bactrianCamel32);
  static Set<String> waterBuffaloMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.waterBuffalo32);
  static Set<String> oxMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ox32);
  static Set<String> ramMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ram32);
  static Set<String> ratMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.rat32);
  static Set<String> catFaceMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.catFace32);
  static Set<String> donkeyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.donkey32);
  static Set<String> crowBirdMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.crowBird32);
  static Set<String> featherMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.feather32);
  static Set<String> nestMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.nest32);
  static Set<String> wingMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wing32);
  static Set<String> sledMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.sled32);
  static Set<String> iceSkateMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.iceSkate32);
  static Set<String> bowlingMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bowling32);
  static Set<String> medalMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.medal32);
  static Set<String> yoyoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.yoyo32);
  static Set<String> nestingDollsMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.nestingDolls32);
  static Set<String> scissorsMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.scissors32);
  static Set<String> axeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.axe32);
  static Set<String> wrenchMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wrench32);
  static Set<String> magnetMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.magnet32);
  static Set<String> testTubeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.testTube32);
  static Set<String> microscopeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.microscope32);
  static Set<String> satelliteMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.satellite32);
  static Set<String> banjoMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.banjo32);
  static Set<String> accordionMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.accordion32);
  static Set<String> boneMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.bone32);
  static Set<String> toothMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tooth32);
  static Set<String> flexedBicepsMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.flexedBiceps32);
  static Set<String> wavingHandMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wavingHand32);
  static Set<String> loveYouHandMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.loveYouHand32);
  static Set<String> tshirtMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tshirt32);
  static Set<String> capMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.cap32);
  static Set<String> graduationCapMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.graduationCap32);
  static Set<String> bootMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.boot32);
  static Set<String> ringMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ring32);
  static Set<String> stormCloudMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.stormCloud32);
  static Set<String> waveMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.wave32);
  static Set<String> classicalBuildingMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.classicalBuilding32);
  static Set<String> tentMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tent32);
  static Set<String> fountainMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.fountain32);
  static Set<String> tractorMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.tractor32);
  static Set<String> racingCarMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.racingCar32);
  static Set<String> canoeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.canoe32);
  static Set<String> shipMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.ship32);
  static Set<String> coffeeMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.coffee32);
  static Set<String> lemonMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.lemon32);
  static Set<String> broccoliMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.broccoli32);
  static Set<String> cornMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.corn32);
  static Set<String> hotPepperMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.hotPepper32);
  static Set<String> garlicMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.garlic32);
  static Set<String> poultryLegMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.poultryLeg32);
  static Set<String> candyMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.candy32);
  static Set<String> honeyPotMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.honeyPot32);
  static Set<String> pretzelMask(int side) =>
      _bitmapMask(side, BitmapAnimalTemplates.pretzel32);

  /// Globe (circle + 3 latitude line strips)
  static Set<String> globeMask(int side) {
    final mask = <String>{}; final s = side.toDouble();
    _ellipse(mask, side, s*0.50, s*0.50, s*0.44, s*0.44); // sphere
    // Latitude line shadows (small rect strips that partially overlap — just add them)
    // They're already included in the ellipse so this is purely visual context.
    // To make it distinct, subtract thin equatorial band and re-add narrow strips:
    // (Keep simple: just the full circle. The globe identity comes from context.)
    return _clean(mask, side);
  }

  // ── Legacy public alias (for compatibility with existing level_repository) ──
  static Set<String> maskForLevel(int levelNumber, Random rng, int side) {
    final type = AppConstants.levelTypeFor(levelNumber);
    return maskForLevelType(type, rng, side);
  }
}
