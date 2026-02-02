import 'package:flutter/material.dart';
import 'game/game_controller.dart';
import 'game/dish_painter.dart';
import 'ui/panels.dart';

final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

void _toggleThemeMode() {
  _themeMode.value = _themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

void main() => runApp(const ImmuneArchitectApp());

class ImmuneArchitectApp extends StatelessWidget {
  const ImmuneArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Bio-Defense: Cell Lab',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
          ),
          themeMode: mode,
          home: const AppRoot(),
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late List<BoardNode> _path;
  Difficulty _difficulty = Difficulty.normal;
  bool _inGame = false;
  GameController? _controller;
  int _currentIndex = 0;
  bool _campaignStarted = false;

  @override
  void initState() {
    super.initState();
    _path = _buildBodyPath();
    _controller = GameController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<BoardNode> _buildBodyPath() {
    return [
      BoardNode(
        id: "entry",
        title: "Dermal Entry",
        preset: const BoardPreset(
          id: "entry",
          name: "Dermal Entry",
          desc: "Left → Right flow along a capillary.",
          spawnEdge: BoardEdge.left,
          exitEdge: BoardEdge.right,
          targetWave: 3,
          accent: Colors.redAccent,
        ),
        position: const Offset(0.15, 0.70),
        unlocked: true,
      ),
      BoardNode(
        id: "vein",
        title: "Vein Bend",
        preset: const BoardPreset(
          id: "vein",
          name: "Vein Bend",
          desc: "Right → Left reverse flow.",
          spawnEdge: BoardEdge.right,
          exitEdge: BoardEdge.left,
          targetWave: 4,
          accent: Colors.deepOrangeAccent,
        ),
        position: const Offset(0.35, 0.45),
      ),
      BoardNode(
        id: "artery",
        title: "Artery Run",
        preset: const BoardPreset(
          id: "artery",
          name: "Artery Run",
          desc: "Top → Bottom rapid descent.",
          spawnEdge: BoardEdge.top,
          exitEdge: BoardEdge.bottom,
          targetWave: 5,
          accent: Colors.orangeAccent,
        ),
        position: const Offset(0.55, 0.28),
      ),
      BoardNode(
        id: "chamber",
        title: "Heart Chamber",
        preset: const BoardPreset(
          id: "chamber",
          name: "Heart Chamber",
          desc: "Bottom → Top reflux pressure.",
          spawnEdge: BoardEdge.bottom,
          exitEdge: BoardEdge.top,
          targetWave: 6,
          accent: Colors.pinkAccent,
        ),
        position: const Offset(0.72, 0.52),
      ),
      BoardNode(
        id: "core",
        title: "Core Organ",
        preset: const BoardPreset(
          id: "core",
          name: "Core Organ",
          desc: "Left → Right final defense.",
          spawnEdge: BoardEdge.left,
          exitEdge: BoardEdge.right,
          targetWave: 7,
          accent: Colors.redAccent,
        ),
        position: const Offset(0.85, 0.80),
      ),
    ];
  }

  void _startBoard(int index) {
    final node = _path[index];
    if (!node.unlocked) return;
    final controller = _controller!;
    if (!_campaignStarted) {
      controller.setDifficulty(_difficulty);
      _campaignStarted = true;
    }
    controller.setBoardPreset(node.preset);
    controller.start();
    setState(() {
      _currentIndex = index;
      _inGame = true;
    });
  }

  void _exitToMap({required bool completed}) {
    if (completed) {
      _path[_currentIndex].completed = true;
      if (_currentIndex + 1 < _path.length) {
        _path[_currentIndex + 1].unlocked = true;
      }
    }
    setState(() {
      _inGame = false;
    });
  }

  void _resetCampaign() {
    _controller?.dispose();
    _controller = GameController();
    _path = _buildBodyPath();
    _campaignStarted = false;
    _currentIndex = 0;
    setState(() {
      _inGame = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_inGame) {
      final canChangeDifficulty = !_campaignStarted;
      return StartScreen(
        path: _path,
        difficulty: _difficulty,
        onDifficultyChanged: canChangeDifficulty ? (d) => setState(() => _difficulty = d) : null,
        canChangeDifficulty: canChangeDifficulty,
        onStartBoard: _startBoard,
        onResetCampaign: _resetCampaign,
        onToggleTheme: _toggleThemeMode,
        themeMode: _themeMode.value,
      );
    }

    return GameScreen(
      controller: _controller!,
      onExitToMap: _exitToMap,
    );
  }
}

class BoardNode {
  final String id;
  final String title;
  final BoardPreset preset;
  final Offset position;
  bool unlocked;
  bool completed;

  BoardNode({
    required this.id,
    required this.title,
    required this.preset,
    required this.position,
    this.unlocked = false,
    this.completed = false,
  });
}

class StartScreen extends StatelessWidget {
  final List<BoardNode> path;
  final Difficulty difficulty;
  final ValueChanged<Difficulty>? onDifficultyChanged;
  final bool canChangeDifficulty;
  final void Function(int index) onStartBoard;
  final VoidCallback onResetCampaign;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const StartScreen({
    super.key,
    required this.path,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.canChangeDifficulty,
    required this.onStartBoard,
    required this.onResetCampaign,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bio-Defense: Cell Lab — Body Path"),
        actions: [
          IconButton(
            tooltip: "Toggle theme",
            onPressed: onToggleTheme,
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = constraints.maxHeight * 0.68;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose your route through the body.",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  "Complete boards in order to unlock the next region.",
                  style: TextStyle(color: onSurface.withOpacity(0.70), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Difficulty", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: Difficulty.values.map((d) {
                          return ChoiceChip(
                            selected: difficulty == d,
                            label: Text(d.name),
                            onSelected: canChangeDifficulty ? (_) => onDifficultyChanged?.call(d) : null,
                          );
                        }).toList(),
                      ),
                      if (!canChangeDifficulty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Difficulty locked for this body path.",
                          style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: onResetCampaign,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reset Body Path"),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: mapHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return Stack(
                        children: [
                          CustomPaint(
                            size: mapSize,
                            painter: BodyMapPainter(
                              nodes: path,
                              lineColor: onSurface.withOpacity(0.25),
                            ),
                          ),
                          for (int i = 0; i < path.length; i++)
                            _BoardNodeButton(
                              node: path[i],
                              mapSize: mapSize,
                              onTap: path[i].unlocked ? () => onStartBoard(i) : null,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Selected boards are short runs (3–7 waves) that scale in difficulty.",
                  style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BoardNodeButton extends StatelessWidget {
  final BoardNode node;
  final Size mapSize;
  final VoidCallback? onTap;

  const _BoardNodeButton({required this.node, required this.mapSize, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pos = Offset(mapSize.width * node.position.dx, mapSize.height * node.position.dy);
    final color = node.completed ? Colors.green : (node.unlocked ? node.preset.accent : Colors.grey);
    return Positioned(
      left: pos.dx - 48,
      top: pos.dy - 24,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.20),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(node.unlocked ? 0.90 : 0.30),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              node.title,
              style: TextStyle(fontWeight: FontWeight.w700, color: node.unlocked ? null : Colors.grey),
            ),
            Text(
              "${node.preset.targetWave} waves",
              style: TextStyle(fontSize: 12, color: node.unlocked ? Colors.black54 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class BodyMapPainter extends CustomPainter {
  final List<BoardNode> nodes;
  final Color lineColor;

  BodyMapPainter({required this.nodes, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodes.length - 1; i++) {
      final a = Offset(size.width * nodes[i].position.dx, size.height * nodes[i].position.dy);
      final b = Offset(size.width * nodes[i + 1].position.dx, size.height * nodes[i + 1].position.dy);
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameScreen extends StatefulWidget {
  final GameController controller;
  final void Function({required bool completed}) onExitToMap;

  const GameScreen({super.key, required this.controller, required this.onExitToMap});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController get controller => widget.controller;

  void _openRewardModalIfNeeded() {
    if (controller.gameOver || !controller.rewardPending || controller.rewardModalOpen) return;

    controller.rewardModalOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!controller.rewardPending || controller.gameOver) {
        controller.rewardModalOpen = false;
        return;
      }
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => RewardPicker(
          controller: controller,
          onPick: (card) {
            controller.pickReward(card);
            Navigator.of(context).pop();
          },
          onOpenResearch: () {
            Navigator.of(context).pop();
            _openResearchModal();
          },
        ),
      );

      controller.rewardModalOpen = false;
    });
  }

  void _openResearchModal() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetWidth = screenWidth * 0.95;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: targetWidth),
      builder: (_) => SizedBox(
        width: targetWidth,
        child: ResearchPanel(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        _openRewardModalIfNeeded();

        return Scaffold(
          appBar: AppBar(
            title: Text("Bio-Defense: Cell Lab — ${controller.boardPreset.name}"),
            actions: [
              IconButton(
                tooltip: "Body Map",
                onPressed: () => widget.onExitToMap(completed: controller.victory),
                icon: const Icon(Icons.map_outlined),
              ),
              IconButton(
                tooltip: "Toggle theme",
                onPressed: _toggleThemeMode,
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                tooltip: "Research",
                onPressed: _openResearchModal,
                icon: const Icon(Icons.hub_outlined),
              ),
              IconButton(
                tooltip: "Reset",
                onPressed: () => controller.reset(preserveResearch: true),
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (_, c) {
              final wide = c.maxWidth > 900;
              return wide
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: BoardView(controller: controller)),
                        Expanded(flex: 2, child: SidePanel(controller: controller)),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 3, child: BoardView(controller: controller)),
                        Expanded(flex: 2, child: SidePanel(controller: controller)),
                      ],
                    );
            },
          ),
        );
      },
    );
  }
}

/// Free placement board view
class BoardView extends StatelessWidget {
  final GameController controller;
  const BoardView({super.key, required this.controller});

  Offset _toNormalized(Offset local, Size size) {
    final nx = (local.dx / size.width).clamp(0.0, 1.0);
    final ny = (local.dy / size.height).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final side = constraints.biggest.shortestSide;

              return SizedBox(
                width: side,
                height: side,
                child: MouseRegion(
                  onHover: (ev) => controller.setHover(_toNormalized(ev.localPosition, Size(side, side))),
                  onExit: (_) => controller.setHover(null),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final pos = _toNormalized(d.localPosition, Size(side, side));
                      controller.placeCellAt(pos);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: DishPainter(
                          controller,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
