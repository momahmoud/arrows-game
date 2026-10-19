import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_fonts.dart';
import '../core/constants.dart';
import '../data/repositories/level_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../screens/game/game_screen.dart';
import '../screens/game_over/game_over_screen.dart';
import '../ui/game_ui.dart';

/// Development-only sandbox for comparing production vs the first-500
/// quality candidate without touching the player's real progress or
/// registering candidate binaries as production assets.
///
/// Requires [AppConstants.enableFirst500Playtest]. Uses an isolated
/// [ProgressRepository] / [LevelRepository] and a nested [Navigator] so
/// `/menu` and `/game` stay inside the sandbox.
class First500PlaytestScreen extends StatefulWidget {
  const First500PlaytestScreen({super.key});

  @override
  State<First500PlaytestScreen> createState() => _First500PlaytestScreenState();
}

enum _BinSource { production, candidate }

class _First500PlaytestScreenState extends State<First500PlaytestScreen> {
  late final ProgressRepository _sandboxProgress;
  late final LevelRepository _sandboxLevels;

  @override
  void initState() {
    super.initState();
    _sandboxProgress = ProgressRepository();
    _sandboxLevels = LevelRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final root = context.read<ProgressRepository>();
      _sandboxProgress.setThemeMode(root.themeMode);
      _sandboxProgress.setLanguageCode(root.languageCode);
      _sandboxProgress.setSoundEnabled(root.soundEnabled);
      _sandboxProgress.setMusicEnabled(root.musicEnabled);
      _sandboxProgress.setVibrationEnabled(root.vibrationEnabled);
    });
  }

  @override
  void dispose() {
    _sandboxProgress.dispose();
    super.dispose();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/menu';
    switch (name) {
      case '/game':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GameScreen(),
        );
      case '/game_over':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GameOverScreen(),
        );
      case '/menu':
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _PlaytestHub(
            levels: _sandboxLevels,
            onCloseSandbox: () =>
                Navigator.of(this.context, rootNavigator: true).pop(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.enableFirst500Playtest) {
      return Scaffold(
        body: Center(
          child: Text(
            'First-500 playtest is disabled.\n'
            'Pass --dart-define=ENABLE_FIRST500_PLAYTEST=true '
            '(debug/profile only).',
            textAlign: TextAlign.center,
            style: AppFonts.style(fontSize: 14),
          ),
        ),
      );
    }

    // Nested navigator only — do not rebuild this tree on sandbox progress
    // notifications (level clears), or the stack would reset mid-session.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgressRepository>.value(
          value: _sandboxProgress,
        ),
        Provider<LevelRepository>.value(value: _sandboxLevels),
      ],
      child: Navigator(
        initialRoute: '/menu',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

class _PlaytestHub extends StatefulWidget {
  const _PlaytestHub({
    required this.levels,
    required this.onCloseSandbox,
  });

  final LevelRepository levels;
  final VoidCallback onCloseSandbox;

  @override
  State<_PlaytestHub> createState() => _PlaytestHubState();
}

class _PlaytestHubState extends State<_PlaytestHub> {
  final _levelField = TextEditingController(text: '12');

  Uint8List? _productionBytes;
  Uint8List? _candidateBytes;
  _BinSource _source = _BinSource.candidate;
  String? _error;
  bool _ready = false;
  int? _levelCount;

  static const _priorityJumps = <(int, String)>[
    (3, 'P0 tutorial→learn'),
    (4, 'P0 first 1B'),
    (12, 'P0 first trap'),
    (24, 'P0 special'),
    (25, 'P0 mid handoff'),
    (50, 'P0 repaired'),
    (97, 'P0 repaired'),
    (210, 'P0 open rescue'),
    (217, 'P0 open rescue'),
    (220, 'P0 open rescue'),
    (230, 'P0 repaired'),
    (239, 'P0 worst dead'),
    (250, 'P0 cliff before'),
    (251, 'P0 2A start'),
    (255, 'P0 2A trap'),
    (270, 'P0 2A trap'),
    (300, 'P0 2A end'),
    (301, 'P0 2B start'),
    (320, 'P1 2B'),
    (346, 'P1 2B'),
    (350, 'P1 boundary'),
    (351, 'P1 boundary'),
    (376, 'P1 duration'),
    (399, 'P1 duration'),
    (400, 'P1 boundary'),
    (401, 'P1 boundary'),
    (434, 'P1 duration'),
    (450, 'P1 boundary'),
    (451, 'P1 boundary'),
    (463, 'P1 short'),
    (474, 'P1 short'),
    (481, 'P1 short'),
    (487, 'P1 short'),
    (488, 'P1 short'),
    (500, 'P1 handoff'),
    (501, 'P1 prod again'),
    (10, 'P2 silhouette'),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Host-relative paths work on desktop; on Android the candidate must be
  /// pushed to device storage (see playtest doc) or given as an absolute path.
  static List<String> _candidateSearchPaths() {
    const pushedName = 'first_500_levels_candidate.bin';
    return [
      AppConstants.first500PlaytestBinPath,
      '/data/local/tmp/$pushedName',
      '/sdcard/Download/$pushedName',
      '/storage/emulated/0/Download/$pushedName',
    ];
  }

  File? _findCandidateFile() {
    for (final path in _candidateSearchPaths()) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }

  Future<void> _bootstrap() async {
    try {
      final prodData = await rootBundle.load('assets/levels.bin');
      _productionBytes = prodData.buffer.asUint8List(
        prodData.offsetInBytes,
        prodData.lengthInBytes,
      );

      final file = _findCandidateFile();
      if (file == null) {
        if (!mounted) return;
        final tried = _candidateSearchPaths().map((p) => '  • $p').join('\n');
        setState(() {
          _error =
              'Candidate not found on this device.\n\n'
              'Host-relative paths are not visible inside Android/iOS apps.\n'
              'From the machine:\n'
              '  adb push build/candidates/first_500_quality/levels_candidate.bin '
              '/data/local/tmp/first_500_levels_candidate.bin\n'
              'Then hot-restart, or set FIRST500_PLAYTEST_BIN to that absolute path.\n\n'
              'Tried:\n$tried';
        });
        return;
      }
      _candidateBytes = file.readAsBytesSync();
      _applySource(_source);
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load playtest binaries: $e');
    }
  }

  void _applySource(_BinSource source) {
    final bytes =
        source == _BinSource.candidate ? _candidateBytes! : _productionBytes!;
    widget.levels.debugAttachPlaytestBinary(bytes);
    _source = source;
    _levelCount = widget.levels.packagedLevelCount;
  }

  void _playLevel(int level) {
    if (!_ready) return;
    final n = level.clamp(1, AppConstants.totalLevels);
    Navigator.of(context).pushNamed(
      '/game',
      arguments: {'level': n},
    );
  }

  @override
  void dispose() {
    _levelField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Exit playtest sandbox',
                      onPressed: widget.onCloseSandbox,
                      icon: const GameIcon(kind: GameIconKind.back, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        'First-500 playtest (dev)',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Isolated progress. Arrow rules unchanged. '
                  'Candidate is not a production asset.',
                  style: AppFonts.style(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: AppFonts.style(
                      color: const Color(0xFFC0392B),
                      fontSize: 13,
                    ),
                  ),
                ),
              if (!_ready && _error == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_ready) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<_BinSource>(
                    segments: const [
                      ButtonSegment(
                        value: _BinSource.production,
                        label: Text('Production'),
                      ),
                      ButtonSegment(
                        value: _BinSource.candidate,
                        label: Text('Candidate'),
                      ),
                    ],
                    selected: {_source},
                    onSelectionChanged: (s) {
                      setState(() => _applySource(s.first));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _source == _BinSource.candidate
                        ? 'Candidate · $_levelCount levels\n'
                            '${AppConstants.first500PlaytestBinPath}'
                        : 'Production assets/levels.bin · $_levelCount levels',
                    style: AppFonts.style(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _levelField,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Level ID',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (raw) {
                            final n = int.tryParse(raw.trim());
                            if (n != null) _playLevel(n);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final n = int.tryParse(_levelField.text.trim());
                          if (n != null) _playLevel(n);
                        },
                        child: const Text('Play'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Priority jumps',
                    style: AppFonts.style(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: _priorityJumps.length,
                    itemBuilder: (context, i) {
                      final (id, label) = _priorityJumps[i];
                      return ListTile(
                        dense: true,
                        title: Text('Level $id'),
                        subtitle: Text(label),
                        trailing: const GameIcon(
                          kind: GameIconKind.play,
                          size: 18,
                        ),
                        onTap: () {
                          _levelField.text = '$id';
                          _playLevel(id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
