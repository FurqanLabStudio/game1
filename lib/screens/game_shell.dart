import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/game_engine.dart';
import '../core/players.dart';
import '../widgets/control_layout.dart';

enum _Phase { countdown, playing, finished }

/// Har game ki screen: game loop, 3-2-1 countdown, pause, result aur
/// har player ki jeet ka hisaab yahin hota hai.
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.playerCount,
    required this.createEngine,
  });

  final String title;
  final int playerCount;
  final GameEngine Function(int playerCount) createEngine;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  Duration? _lastTick;
  _Phase _phase = _Phase.countdown;
  double _countdown = 3;
  bool _paused = false;
  double? _aspect;
  late List<int> _wins;

  @override
  void initState() {
    super.initState();
    _engine = widget.createEngine(widget.playerCount);
    _wins = List<int>.filled(widget.playerCount, 0);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null || _aspect == null || _paused) return;

    double dt = (elapsed - last).inMicroseconds / 1000000.0;
    if (dt > 0.05) dt = 0.05; // phone atak jaye to game teleport na kare
    if (dt <= 0) return;

    switch (_phase) {
      case _Phase.countdown:
        final before = _countdown.ceil();
        _countdown -= dt;
        if (_countdown <= 0) {
          setState(() => _phase = _Phase.playing);
        } else if (_countdown.ceil() != before) {
          setState(() {});
        }
        break;
      case _Phase.playing:
        _engine.update(dt);
        if (_engine.roundOver) {
          for (final w in _engine.winners) {
            _wins[w]++;
          }
          HapticFeedback.mediumImpact();
          setState(() => _phase = _Phase.finished);
        }
        break;
      case _Phase.finished:
        break;
    }
    _frame.value++;
  }

  void _newRound() {
    setState(() {
      _paused = false;
      _phase = _Phase.countdown;
      _countdown = 3;
      final aspect = _aspect;
      if (aspect != null) _engine.setup(aspect);
    });
  }

  void _togglePause() {
    if (_phase == _Phase.finished) return;
    setState(() => _paused = !_paused);
  }

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PlayerControlsLayout(
          playerCount: widget.playerCount,
          arena: _buildArena(),
          zoneBuilder: (i) => _engine.buildControls(context, i),
        ),
      ),
    );
  }

  Widget _buildArena() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = constraints.maxHeight / constraints.maxWidth;
        final current = _aspect;
        if (current == null || (aspect - current).abs() > 0.01) {
          _aspect = aspect;
          _engine.setup(aspect);
        }
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(painter: _engine.createPainter(_frame)),
              ),
              if (_phase == _Phase.countdown && !_paused) _buildCountdown(),
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(child: _roundIconButton(Icons.pause_rounded, _togglePause)),
              ),
              if (_phase == _Phase.finished) _buildResult(),
              if (_paused) _buildPause(),
            ],
          ),
        );
      },
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withAlpha(110),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// Text jo dono taraf se parha ja sake: aik seedha, aik ulta.
  Widget _twoSided(Widget Function() builder) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RotatedBox(quarterTurns: 2, child: builder()),
        builder(),
      ],
    );
  }

  Widget _buildCountdown() {
    final n = _countdown.ceil().clamp(1, 3);
    return IgnorePointer(
      child: _twoSided(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$n',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final winners = _engine.winners;
    final String message;
    Color color = Colors.white;
    if (winners.isEmpty) {
      message = 'Draw!';
    } else if (winners.length == 1) {
      message = '${kPlayers[winners.first].name} wins!';
      color = kPlayers[winners.first].color;
    } else {
      message = 'Tie: ${winners.map((w) => kPlayers[w].name).join(' & ')}';
    }

    Widget banner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 6),
            if (_engine.resultDetail != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _engine.resultDetail!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            _scoreRow(),
          ],
        );

    return Container(
      color: Colors.black.withAlpha(170),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RotatedBox(quarterTurns: 2, child: banner()),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _newRound,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Next round'),
              ),
              OutlinedButton.icon(
                onPressed: _exit,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Menu'),
              ),
            ],
          ),
          banner(),
        ],
      ),
    );
  }

  Widget _scoreRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        for (int i = 0; i < widget.playerCount; i++)
          Padding(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPlayers[i].color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${kPlayers[i].shortName}: ${_wins[i]}',
                style: TextStyle(
                  color: kPlayers[i].onColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPause() {
    return Container(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _togglePause,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _newRound,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restart round'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _exit,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
