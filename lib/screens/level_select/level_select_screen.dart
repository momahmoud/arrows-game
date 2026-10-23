import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/audio_manager.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final args = ModalRoute.of(context)?.settings.arguments;
    final holdScroll = args is Map && args['focus'] == false;

    return Scaffold(
      body: Container(
        color: AppColors.isDark ? null : const Color(0xFFFFFFFF),
        decoration: AppColors.isDark
            ? BoxDecoration(gradient: AppColors.bgGradient)
            : null,
        child: SafeArea(
          child: Column(
            children: [
              LevelSelectHeader(title: context.l10n.selectLevel),
              Expanded(
                child: LevelGrid(
                  currentLevel: progress.currentLevel,
                  total: AppConstants.totalLevels,
                  unlocked: (_) => true,
                  // unlocked: progress.isLevelUnlocked,
                  starsFor: progress.getStarsForLevel,
                  centerOnCurrent: !holdScroll,
                  onOpen: (level) {
                    AudioManager.instance.playClick();
                    Navigator.pushReplacementNamed(
                      context,
                      '/game',
                      arguments: {'level': level},
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

class LevelSelectHeader extends StatelessWidget {
  const LevelSelectHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GameScreenHeader(title: title, onBack: onBack);
  }
}

/// Five-column level path. Number order stays left to right in Arabic.
class LevelGrid extends StatefulWidget {
  const LevelGrid({
    super.key,
    required this.currentLevel,
    required this.total,
    required this.unlocked,
    required this.starsFor,
    required this.onOpen,
    this.centerOnCurrent = true,
  });

  static const columns = 5;
  static const gap = 12.0;
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 16);
  static const aspect = 0.82;

  final int currentLevel;
  final int total;
  final bool Function(int level) unlocked;
  final int Function(int level) starsFor;
  final ValueChanged<int> onOpen;
  final bool centerOnCurrent;

  @override
  State<LevelGrid> createState() => _LevelGridState();
}

class _LevelGridState extends State<LevelGrid> {
  final ScrollController _scroll = ScrollController();
  bool _centered = false;

  @override
  void initState() {
    super.initState();
    if (widget.centerOnCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _center());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _center() {
    if (!mounted || _centered) return;
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _center());
      return;
    }
    _centered = true;
    final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
    final viewport = _scroll.position.viewportDimension;
    final target = _offsetFor(widget.currentLevel, width, viewport);
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0.0, max));
  }

  double _offsetFor(int level, double gridWidth, double viewport) {
    const padH = 16.0;
    const padV = 8.0;
    final cellW =
        (gridWidth - padH * 2 - LevelGrid.gap * (LevelGrid.columns - 1)) /
            LevelGrid.columns;
    final cellH = cellW / LevelGrid.aspect;
    final row = (level - 1) ~/ LevelGrid.columns;
    final top = padV + row * (cellH + LevelGrid.gap);
    return top - (viewport - cellH) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.builder(
        controller: _scroll,
        padding: LevelGrid.padding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: LevelGrid.columns,
          mainAxisSpacing: LevelGrid.gap,
          crossAxisSpacing: LevelGrid.gap,
          childAspectRatio: LevelGrid.aspect,
        ),
        itemCount: widget.total,
        itemBuilder: (context, index) {
          final level = index + 1;
          final open = widget.unlocked(level);
          final stars = widget.starsFor(level);
          final type = AppConstants.levelTypeFor(level);
          return LevelCard(
            levelNumber: level,
            unlocked: open,
            current: level == widget.currentLevel,
            stars: stars,
            levelType: type,
            onTap: open ? () => widget.onOpen(level) : null,
          );
        },
      ),
    );
  }
}
