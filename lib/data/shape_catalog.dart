import 'models/level.dart';
import 'shape_names_ar.dart';

enum ShapeCategory {
  geometric('Shapes'),
  animals('Animals'),
  nature('Nature'),
  food('Food'),
  objects('Objects'),
  music('Music'),
  characters('Characters');

  final String label;
  const ShapeCategory(this.label);
}

/// Display names and album groups for mask silhouettes.
class ShapeCatalog {
  ShapeCatalog._();

  static const _geometric = {
    'square', 'longRectangle', 'circle', 'heart', 'star', 'diamond', 'hexagon',
    'blob', 'plus', 'tShape', 'lShape', 'hShape', 'uShape', 'zShape', 'xCross',
    'arrowUp', 'arrowRight', 'chevron', 'staircase', 'trapezoid', 'parallelogram',
    'pentagon', 'octagon', 'pinwheel', 'gear', 'lightningBolt', 'star4', 'ribbon',
    'gem', 'crescentMoon', 'snowflake',
  };

  static const _nature = {
    'tree', 'palmTree', 'flower', 'cactus', 'mushroom', 'mapleLeaf', 'clover',
    'tulip', 'sunflower', 'lotus', 'coral', 'wave', 'stormCloud', 'cloud', 'sun',
    'tornado', 'fire', 'volcano',
  };

  static const _food = {
    'apple', 'pear', 'strawberry', 'pineapple', 'banana', 'carrot', 'grapes',
    'cupcake', 'iceCream', 'lollipop', 'pizza', 'donut', 'croissant',
    'birthdayCake', 'coffee', 'lemon', 'broccoli', 'corn', 'hotPepper', 'garlic',
    'poultryLeg', 'candy', 'honeyPot', 'pretzel', 'dates',
  };

  static const _music = {
    'guitar', 'saxophone', 'trumpet', 'drum', 'banjo', 'accordion', 'microphone',
  };

  static const _characters = {
    'ghost', 'spaceInvader', 'unicorn', 'mermaid', 'fairy', 'genie', 'wizard',
    'ninja', 'phoenix', 'snowman', 'flexedBiceps', 'wavingHand', 'loveYouHand',
    'teddyBear', 'androidBot',
  };

  static const _animals = {
    'cat', 'dog', 'frog', 'fox', 'tiger', 'panda', 'fish', 'bird', 'butterfly',
    'seaTurtle', 'owl', 'camel', 'lion', 'elephant', 'rabbit', 'duck', 'scorpion',
    'horse', 'wolf', 'bear', 'pig', 'bee', 'snake', 'whale', 'dolphin', 'crab',
    'penguin', 'cow', 'sheep', 'eagle', 'parrot', 'mouse', 'gorilla', 'gecko',
    'chick', 'giraffe', 'zebra', 'deer', 'kangaroo', 'hippo', 'rhino', 'monkey',
    'leopard', 'dinosaur', 'trex', 'dragon', 'octopus', 'shark', 'squid',
    'lobster', 'tropicalFish', 'blowfish', 'seal', 'peacock', 'swan', 'rooster',
    'turkey', 'dove', 'dodo', 'bat', 'hedgehog', 'squirrel', 'sloth', 'otter',
    'llama', 'goat', 'bison', 'mammoth', 'poodle', 'ant', 'ladybug', 'snail',
    'spider', 'jellyfish', 'moose', 'goose', 'crowBird', 'feather', 'nest',
    'wing', 'hatchingChick', 'crocodile', 'bactrianCamel', 'waterBuffalo', 'ox',
    'ram', 'rat', 'catFace', 'donkey', 'guideDog', 'orangutan', 'skunk',
    'raccoon', 'badger', 'beaver', 'fly', 'worm', 'caterpillar', 'falcon',
  };

  static String displayName(MaskShape shape, {String languageCode = 'en'}) {
    if (languageCode == 'ar') {
      final ar = shapeNamesAr[shape.name];
      if (ar != null) return ar;
    }
    final raw = shape.name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    if (raw.isEmpty) return shape.name;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static ShapeCategory categoryOf(MaskShape shape) {
    final name = shape.name;
    if (_geometric.contains(name)) return ShapeCategory.geometric;
    if (_animals.contains(name)) return ShapeCategory.animals;
    if (_nature.contains(name)) return ShapeCategory.nature;
    if (_food.contains(name)) return ShapeCategory.food;
    if (_music.contains(name)) return ShapeCategory.music;
    if (_characters.contains(name)) return ShapeCategory.characters;
    return ShapeCategory.objects;
  }

  static Map<ShapeCategory, List<MaskShape>> grouped() {
    final map = {for (final c in ShapeCategory.values) c: <MaskShape>[]};
    for (final shape in MaskShape.values) {
      map[categoryOf(shape)]!.add(shape);
    }
    return map;
  }
}
