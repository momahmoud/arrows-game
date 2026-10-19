import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/models/level.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/shape_catalog.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class ShapeAlbumScreen extends StatelessWidget {
  const ShapeAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final groups = ShapeCatalog.grouped();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              GameScreenHeader(title: context.l10n.shapeAlbum),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    context.l10n.shapesUncovered(progress.unlockedShapeCount),
                    style: GameTypography.body(GameColors.textMuted),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (progress.unlockedShapeCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          context.l10n.albumEmpty,
                          style: GameTypography.body(GameColors.textMuted),
                        ),
                      ),
                    for (final category in ShapeCategory.values)
                      if (groups[category]!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            context.l10n.shapeCategory(category),
                            style: AppFonts.style(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: groups[category]!.length,
                          itemBuilder: (context, i) {
                            final shape = groups[category]![i];
                            final owned = progress.hasShape(shape);
                            return _ShapeTile(shape: shape, owned: owned);
                          },
                        ),
                      ],
                  ],
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
  final MaskShape shape;
  final bool owned;

  const _ShapeTile({required this.shape, required this.owned});

  @override
  Widget build(BuildContext context) {
    final name = context.l10n.shapeName(shape);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: GameDecor.card(highlight: owned),
      child: Opacity(
        opacity: owned ? 1 : 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameIcon(
              kind: owned ? GameIconKind.album : GameIconKind.levelLocked,
              size: GameIconSizes.feature,
            ),
            const SizedBox(height: 6),
            Text(
              owned ? name : '???',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GameTypography.caption(
                owned ? GameColors.text : GameColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
