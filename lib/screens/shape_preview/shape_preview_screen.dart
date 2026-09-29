import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/audio_manager.dart';
import '../../data/level_generator/level_generator_v2.dart';
import '../../data/level_generator/mask_generator_v2.dart';
import '../../data/models/level.dart';

class ShapePreviewGenerateArgs {
  final MaskShape maskShape;
  final LevelType type;
  final int gridSize;
  final int seedSalt;

  const ShapePreviewGenerateArgs({
    required this.maskShape,
    required this.type,
    required this.gridSize,
    required this.seedSalt,
  });
}

const _kPreviewThumbnailSide = 22;

const _heritageShapes = {
  MaskShape.palmTree,
  MaskShape.dallah,
  MaskShape.fanoos,
  MaskShape.dates,
  MaskShape.minaret,
  MaskShape.dhow,
};

const _animalShapes = {
  MaskShape.cat,
  MaskShape.dog,
  MaskShape.frog,
  MaskShape.fox,
  MaskShape.tiger,
  MaskShape.panda,
  MaskShape.fish,
  MaskShape.bird,
  MaskShape.butterfly,
  MaskShape.falcon,
  MaskShape.seaTurtle,
  MaskShape.owl,
  MaskShape.camel,
  MaskShape.lion,
  MaskShape.elephant,
  MaskShape.rabbit,
  MaskShape.duck,
  MaskShape.scorpion,
  MaskShape.horse,
  MaskShape.wolf,
  MaskShape.bear,
  MaskShape.pig,
  MaskShape.bee,
  MaskShape.snake,
  MaskShape.whale,
  MaskShape.dolphin,
  MaskShape.crab,
  MaskShape.penguin,
  MaskShape.cow,
  MaskShape.sheep,
  MaskShape.eagle,
  MaskShape.parrot,
  MaskShape.mouse,
  MaskShape.gorilla,
  MaskShape.gecko,
  MaskShape.chick,
  MaskShape.giraffe,
  MaskShape.zebra,
  MaskShape.deer,
  MaskShape.kangaroo,
  MaskShape.hippo,
  MaskShape.rhino,
  MaskShape.monkey,
  MaskShape.leopard,
  MaskShape.dinosaur,
  MaskShape.trex,
  MaskShape.dragon,
  MaskShape.octopus,
  MaskShape.shark,
  MaskShape.squid,
  MaskShape.lobster,
  MaskShape.tropicalFish,
  MaskShape.blowfish,
  MaskShape.seal,
  MaskShape.peacock,
  MaskShape.swan,
  MaskShape.rooster,
  MaskShape.turkey,
  MaskShape.dove,
  MaskShape.dodo,
  MaskShape.bat,
  MaskShape.hedgehog,
  MaskShape.squirrel,
  MaskShape.sloth,
  MaskShape.otter,
  MaskShape.llama,
  MaskShape.goat,
  MaskShape.bison,
  MaskShape.mammoth,
  MaskShape.poodle,
  MaskShape.ant,
  MaskShape.ladybug,
  MaskShape.snail,
  MaskShape.spider,
  MaskShape.moose,
  MaskShape.goose,
  MaskShape.jellyfish,
  MaskShape.fly,
  MaskShape.worm,
  MaskShape.caterpillar,
  MaskShape.orangutan,
  MaskShape.skunk,
  MaskShape.raccoon,
  MaskShape.badger,
  MaskShape.beaver,
  MaskShape.guideDog,
  MaskShape.hatchingChick,
  MaskShape.crocodile,
  MaskShape.bactrianCamel,
  MaskShape.waterBuffalo,
  MaskShape.ox,
  MaskShape.ram,
  MaskShape.rat,
  MaskShape.catFace,
  MaskShape.donkey,
  MaskShape.crowBird,
  MaskShape.androidBot,
  MaskShape.yarnCluster,
  MaskShape.apple,
};

const _creativeShapes = {
  MaskShape.unicorn,
  MaskShape.mermaid,
  MaskShape.fairy,
  MaskShape.genie,
  MaskShape.wizard,
  MaskShape.ninja,
  MaskShape.ufo,
  MaskShape.phoenix,
  MaskShape.statueOfLiberty,
  MaskShape.circusTent,
  MaskShape.carouselHorse,
  MaskShape.volcano,
  MaskShape.helicopter,
  MaskShape.locomotive,
  MaskShape.motorcycle,
  MaskShape.skateboard,
  MaskShape.saxophone,
  MaskShape.trumpet,
  MaskShape.drum,
  MaskShape.microphone,
  MaskShape.headphones,
  MaskShape.joystick,
  MaskShape.puzzlePiece,
  MaskShape.chessPawn,
  MaskShape.hourglass,
  MaskShape.alarmClock,
  MaskShape.telescope,
  MaskShape.diyaLamp,
  MaskShape.kite,
  MaskShape.lotus,
  MaskShape.coral,
  MaskShape.tornado,
  MaskShape.fire,
  MaskShape.snowman,
  MaskShape.thumbsUp,
  MaskShape.peaceHand,
  MaskShape.pizza,
  MaskShape.donut,
  MaskShape.croissant,
  MaskShape.birthdayCake,
  MaskShape.sneaker,
  MaskShape.highHeel,
  MaskShape.topHat,
  MaskShape.dress,
  MaskShape.feather,
  MaskShape.nest,
  MaskShape.wing,
  MaskShape.sled,
  MaskShape.iceSkate,
  MaskShape.bowling,
  MaskShape.medal,
  MaskShape.yoyo,
  MaskShape.nestingDolls,
  MaskShape.scissors,
  MaskShape.axe,
  MaskShape.wrench,
  MaskShape.magnet,
  MaskShape.testTube,
  MaskShape.microscope,
  MaskShape.satellite,
  MaskShape.banjo,
  MaskShape.accordion,
  MaskShape.bone,
  MaskShape.tooth,
  MaskShape.flexedBiceps,
  MaskShape.wavingHand,
  MaskShape.loveYouHand,
  MaskShape.tshirt,
  MaskShape.cap,
  MaskShape.graduationCap,
  MaskShape.boot,
  MaskShape.ring,
  MaskShape.stormCloud,
  MaskShape.wave,
  MaskShape.classicalBuilding,
  MaskShape.tent,
  MaskShape.fountain,
  MaskShape.tractor,
  MaskShape.racingCar,
  MaskShape.canoe,
  MaskShape.ship,
  MaskShape.coffee,
  MaskShape.lemon,
  MaskShape.broccoli,
  MaskShape.corn,
  MaskShape.hotPepper,
  MaskShape.garlic,
  MaskShape.poultryLeg,
  MaskShape.candy,
  MaskShape.honeyPot,
  MaskShape.pretzel,
};

const _bossGeoShapes = {
  MaskShape.plus,
  MaskShape.tShape,
  MaskShape.lShape,
  MaskShape.hShape,
  MaskShape.uShape,
  MaskShape.zShape,
  MaskShape.xCross,
  MaskShape.arrowUp,
  MaskShape.arrowRight,
  MaskShape.chevron,
  MaskShape.staircase,
  MaskShape.trapezoid,
  MaskShape.parallelogram,
  MaskShape.pentagon,
  MaskShape.octagon,
  MaskShape.pinwheel,
  MaskShape.gear,
  MaskShape.lightningBolt,
  MaskShape.star4,
  MaskShape.ribbon,
};

const _godDecorShapes = {
  MaskShape.heart,
  MaskShape.star,
  MaskShape.diamond,
  MaskShape.hexagon,
  MaskShape.blob,
  MaskShape.circle,
  MaskShape.flower,
  MaskShape.spinningTop,
  MaskShape.lollipop,
  MaskShape.iceCream,
  MaskShape.crescentMoon,
  MaskShape.giftBox,
  MaskShape.anchor,
  MaskShape.shield,
  MaskShape.rocket,
  MaskShape.sun,
  MaskShape.cloud,
  MaskShape.umbrella,
  MaskShape.key,
  MaskShape.bowtie,
  MaskShape.gem,
  MaskShape.snowflake,
  MaskShape.teddyBear,
  MaskShape.globe,
};

LevelModel _generateShapePreviewIsolate(ShapePreviewGenerateArgs args) {
  return LevelGeneratorV2.generateShapePreviewLevel(
    maskShape: args.maskShape,
    type: args.type,
    gridSize: args.gridSize,
    seedSalt: args.seedSalt,
  );
}

/// Dev menu to browse mask silhouettes and play a generated preview level.
class ShapePreviewScreen extends StatefulWidget {
  const ShapePreviewScreen({super.key});

  @override
  State<ShapePreviewScreen> createState() => _ShapePreviewScreenState();
}

class _ShapePreviewScreenState extends State<ShapePreviewScreen> {
  LevelType _levelType = LevelType.god;
  double _gridSize = 35;
  int _seedSalt = 0;
  bool _generating = false;
  String _filter = '';

  static final List<MaskShape> _shapes = MaskShape.values
      .where((s) =>
          s != MaskShape.square && s != MaskShape.longRectangle)
      .toList();

  Future<void> _playShape(MaskShape shape) async {
    if (_generating) return;
    setState(() => _generating = true);

    try {
      final level = await compute(
        _generateShapePreviewIsolate,
        ShapePreviewGenerateArgs(
          maskShape: shape,
          type: _levelType,
          gridSize: _gridSize.round(),
          seedSalt: _seedSalt,
        ),
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        '/game',
        arguments: {
          'previewLevel': level,
          'shapePreview': true,
        },
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _labelFor(MaskShape shape) {
    final name = shape.name;
    return name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _groupFor(MaskShape shape) {
    if (_heritageShapes.contains(shape)) return 'Heritage / Gulf';
    if (_animalShapes.contains(shape)) return 'Animals & birds';
    if (_creativeShapes.contains(shape)) return 'Creative';
    if (_bossGeoShapes.contains(shape)) return 'Boss / geometric';
    if (_godDecorShapes.contains(shape)) return 'God / decorative';
    return 'Objects & other';
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.trim().toLowerCase();
    final filtered = _shapes.where((s) {
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          _labelFor(s).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Shape preview',
                        style: AppFonts.style(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_generating)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _filter = v),
                      decoration: InputDecoration(
                        hintText: 'Search shapes…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.surfaceLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.surfaceLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Level type',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<LevelType>(
                                isExpanded: true,
                                value: _levelType,
                                items: const [
                                  DropdownMenuItem(
                                    value: LevelType.god,
                                    child: Text('God'),
                                  ),
                                  DropdownMenuItem(
                                    value: LevelType.boss,
                                    child: Text('Boss'),
                                  ),
                                ],
                                onChanged: _generating
                                    ? null
                                    : (v) {
                                        if (v != null) {
                                          setState(() => _levelType = v);
                                        }
                                      },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          tooltip: 'New random layout (seed)',
                          onPressed: _generating
                              ? null
                              : () {
                                  AudioManager.instance.playClick();
                                  setState(() => _seedSalt++);
                                },
                          icon: const Icon(Icons.casino_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Grid ${_gridSize.round()}×${_gridSize.round()}',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _gridSize,
                            min: 27,
                            max: 40,
                            divisions: 13,
                            onChanged: _generating
                                ? null
                                : (v) => setState(() => _gridSize = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final shape = filtered[index];
                    return _ShapeTile(
                      title: _labelFor(shape),
                      subtitle: _groupFor(shape),
                      shape: shape,
                      onTap: _generating
                          ? null
                          : () {
                              AudioManager.instance.playClick();
                              _playShape(shape);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final MaskShape shape;
  final VoidCallback? onTap;

  const _ShapeTile({
    required this.title,
    required this.subtitle,
    required this.shape,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ShapeThumbnail(shape: shape),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeThumbnail extends StatelessWidget {
  final MaskShape shape;

  const _ShapeThumbnail({required this.shape});

  @override
  Widget build(BuildContext context) {
    final mask = MaskGeneratorV2.shapeByName(
      shape.name,
      _kPreviewThumbnailSide,
      math.Random(shape.index * 17 + 3),
    );
    return CustomPaint(
      painter: _MaskThumbnailPainter(mask: mask),
      child: const SizedBox.expand(),
    );
  }
}

class _MaskThumbnailPainter extends CustomPainter {
  final Set<String> mask;

  _MaskThumbnailPainter({required this.mask});

  @override
  void paint(Canvas canvas, Size size) {
    if (mask.isEmpty) return;

    int minR = 999, maxR = -1, minC = 999, maxC = -1;
    for (final cell in mask) {
      final p = cell.split(',');
      final r = int.parse(p[0]);
      final c = int.parse(p[1]);
      minR = math.min(minR, r);
      maxR = math.max(maxR, r);
      minC = math.min(minC, c);
      maxC = math.max(maxC, c);
    }

    final gridH = maxR - minR + 1;
    final gridW = maxC - minC + 1;
    final cell = math.min(size.width / gridW, size.height / gridH);
    final offsetX = (size.width - gridW * cell) / 2;
    final offsetY = (size.height - gridH * cell) / 2;

    final fill = Paint()..color = AppColors.primary.withValues(alpha: 0.85);
    for (final cellKey in mask) {
      final p = cellKey.split(',');
      final r = int.parse(p[0]) - minR;
      final c = int.parse(p[1]) - minC;
      final rect = Rect.fromLTWH(
        offsetX + c * cell,
        offsetY + r * cell,
        cell * 0.92,
        cell * 0.92,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.15)),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaskThumbnailPainter oldDelegate) =>
      oldDelegate.mask != mask;
}
