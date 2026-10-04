import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../core/players.dart';
import '../games/paint/paint_game.dart';
import '../games/snakes/snake_game.dart';
import 'game_shell.dart';

class _GameEntry {
  const _GameEntry(this.title, this.howTo, this.icon, this.accent, this.create);

  final String title;
  final String howTo;
  final IconData icon;
  final Color accent;
  final GameEngine Function(int playerCount) create;
}

final List<_GameEntry> _games = [
  _GameEntry(
    'Snakes',
    'Hold left or right to steer. Touch nobody. Last snake alive wins.',
    Icons.gesture_rounded,
    kPlayers[2].color,
    (n) => SnakeEngine(n),
  ),
  _GameEntry(
    'Paint Fight',
    'Drag in your area to steer your brush. Most paint after 40 seconds wins.',
    Icons.format_paint_rounded,
    kPlayers[0].color,
    (n) => PaintEngine(n),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _players = 2;

  void _open(_GameEntry game) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameShell(
          title: game.title,
          playerCount: _players,
          createEngine: game.create,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.table,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            const _ColorTitle('Party Games'),
            const SizedBox(height: 6),
            Text(
              'One phone, up to four friends.',
              style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 16),
            ),
            const SizedBox(height: 28),
            Text(
              'How many players?',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final n in const [2, 3, 4])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PlayerCountButton(
                        count: n,
                        selected: _players == n,
                        onTap: () => setState(() => _players = n),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            for (final g in _games) ...[
              _GameCard(entry: g, onTap: () => _open(g)),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Title ka har harf aik player ke rang mein.
class _ColorTitle extends StatelessWidget {
  const _ColorTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    int c = 0;
    for (final ch in text.split('')) {
      if (ch == ' ') {
        spans.add(const TextSpan(text: ' '));
        continue;
      }
      spans.add(TextSpan(text: ch, style: TextStyle(color: kPlayers[c % 4].color)));
      c++;
    }
    return Text.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          fontSize: 46,
          height: 1.0,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withAlpha(20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.ink : Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < count; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: kPlayers[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.entry, required this.onTap});

  final _GameEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(16),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: entry.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(entry.icon, size: 36, color: AppColors.ink),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.howTo,
                      style: TextStyle(color: Colors.white.withAlpha(185), fontSize: 13.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
