import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/game_engine.dart';
import '../../core/players.dart';
import '../../widgets/joystick_zone.dart';

/// PAINT FIGHT
/// Har player ka brush hai jo chalta rehta hai aur zameen ko apne rang se
/// rangta hai. Joystick se direction badlo. Doosre ka rang apne rang se
/// dhaanp do. Waqt khatam hone par jiska rang sab se zyada, wo jeeta.
class Brush {
  Brush(this.player, this.pos, this.dir);

  final int player;
  Offset pos;
  Offset dir; // unit vector
}

class PaintEngine extends GameEngine {
  PaintEngine(super.playerCount);

  static const int cols = 24;
  static const double brushRadius = 0.055;
  static const double speed = 0.32;
  static const double roundTime = 40;

  final List<Offset> _input = List<Offset>.filled(4, Offset.zero);

  double height = 1.6;
  int rows = 38;
  Uint8List grid = Uint8List(0); // 0 = khali, 1..4 = player ka rang
  List<Brush> brushes = <Brush>[];
  List<int> counts = List<int>.filled(4, 0);
  double timeLeft = roundTime;
  bool _over = false;
  List<int> _winners = <int>[];

  double get cellW => 1.0 / cols;
  double get cellH => height / rows;

  @override
  bool get roundOver => _over;

  @override
  List<int> get winners => _winners;

  @override
  String? get resultDetail {
    final total = cols * rows;
    if (total == 0) return null;
    final parts = <String>[];
    for (int i = 0; i < playerCount; i++) {
      final pct = (counts[i] * 100 / total).round();
      parts.add('${kPlayers[i].name} $pct%');
    }
    return parts.join('   ');
  }

  @override
  void setup(double aspect) {
    height = aspect;
    rows = max(10, (cols * aspect).round());
    grid = Uint8List(cols * rows);
    counts = List<int>.filled(4, 0);
    brushes = [
      for (int i = 0; i < playerCount; i++)
        Brush(
          i,
          Offset(spawnX(i, playerCount), isTopPlayer(i) ? 0.18 : height - 0.18),
          Offset(0.0, isTopPlayer(i) ? 1.0 : -1.0),
        ),
    ];
    timeLeft = roundTime;
    _over = false;
    _winners = <int>[];
    for (final b in brushes) {
      _paintAt(b);
    }
  }

  int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  void _paintAt(Brush b) {
    final cw = cellW;
    final ch = cellH;
    const r = brushRadius;
    final x = b.pos.dx;
    final y = b.pos.dy;
    final c0 = _clampInt(((x - r) / cw).floor(), 0, cols - 1);
    final c1 = _clampInt(((x + r) / cw).floor(), 0, cols - 1);
    final r0 = _clampInt(((y - r) / ch).floor(), 0, rows - 1);
    final r1 = _clampInt(((y + r) / ch).floor(), 0, rows - 1);
    final owner = b.player + 1;
    for (int row = r0; row <= r1; row++) {
      final cy = (row + 0.5) * ch;
      for (int col = c0; col <= c1; col++) {
        final cx = (col + 0.5) * cw;
        final dx = cx - x;
        final dy = cy - y;
        if (dx * dx + dy * dy > r * r) continue;
        final idx = row * cols + col;
        final old = grid[idx];
        if (old == owner) continue;
        if (old > 0) counts[old - 1]--;
        counts[b.player]++;
        grid[idx] = owner;
      }
    }
  }

  @override
  void update(double dt) {
    if (_over) return;
    timeLeft -= dt;

    // 1) Chalao
    for (final b in brushes) {
      final v = _input[b.player];
      final len = v.distance;
      if (len > 0.2) b.dir = v / len;
      b.pos += b.dir * (speed * dt);
    }

    // 2) Brush aapas mein takrayein to door ho jayein
    const minD = brushRadius * 1.6;
    for (int i = 0; i < brushes.length; i++) {
      for (int j = i + 1; j < brushes.length; j++) {
        final a = brushes[i];
        final b = brushes[j];
        final d = b.pos - a.pos;
        final dist = d.distance;
        if (dist < minD && dist > 0.0001) {
          final n = d / dist;
          final push = (minD - dist) / 2;
          a.pos -= n * push;
          b.pos += n * push;
        }
      }
    }

    // 3) Deewar se takra kar wapas
    const m = brushRadius * 0.6;
    for (final b in brushes) {
      double x = b.pos.dx;
      double y = b.pos.dy;
      double dx = b.dir.dx;
      double dy = b.dir.dy;
      if (x < m) {
        x = m;
        dx = dx.abs();
      } else if (x > 1 - m) {
        x = 1 - m;
        dx = -dx.abs();
      }
      if (y < m) {
        y = m;
        dy = dy.abs();
      } else if (y > height - m) {
        y = height - m;
        dy = -dy.abs();
      }
      b.pos = Offset(x, y);
      b.dir = Offset(dx, dy);
      _paintAt(b);
    }

    // 4) Waqt khatam?
    if (timeLeft <= 0) {
      timeLeft = 0;
      _over = true;
      int best = 0;
      for (int i = 0; i < playerCount; i++) {
        best = max(best, counts[i]);
      }
      _winners = best == 0
          ? <int>[]
          : [for (int i = 0; i < playerCount; i++) if (counts[i] == best) i];
    }
  }

  @override
  CustomPainter createPainter(Listenable repaint) => _PaintPainter(this, repaint);

  @override
  Widget buildControls(BuildContext context, int playerIndex) {
    return JoystickZone(
      player: kPlayers[playerIndex],
      flipped: isTopPlayer(playerIndex),
      onChanged: (v) => _input[playerIndex] = v,
    );
  }
}

class _PaintPainter extends CustomPainter {
  _PaintPainter(this.g, Listenable repaint) : super(repaint: repaint);

  final PaintEngine g;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.paper);

    // Rang bhare khane (cells)
    final paints = <Paint>[for (final p in kPlayers) (Paint()..color = p.color)];
    final cw = g.cellW * s;
    final ch = g.cellH * s;
    if (g.grid.length == PaintEngine.cols * g.rows) {
      for (int row = 0; row < g.rows; row++) {
        for (int col = 0; col < PaintEngine.cols; col++) {
          final o = g.grid[row * PaintEngine.cols + col];
          if (o == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(col * cw - 0.5, row * ch - 0.5, cw + 1, ch + 1),
            paints[o - 1],
          );
        }
      }
    }

    // Halki grid lines (kaghaz jaisa)
    final line = Paint()
      ..color = Colors.black.withAlpha(14)
      ..strokeWidth = 1;
    for (int col = 1; col < PaintEngine.cols; col++) {
      canvas.drawLine(Offset(col * cw, 0), Offset(col * cw, size.height), line);
    }
    for (int row = 1; row < g.rows; row++) {
      canvas.drawLine(Offset(0, row * ch), Offset(size.width, row * ch), line);
    }

    // Brushes
    final r = PaintEngine.brushRadius * s;
    for (final b in g.brushes) {
      final c = b.pos * s;
      final color = kPlayers[b.player].color;
      canvas.drawCircle(c + const Offset(0, 3), r * 0.75, Paint()..color = Colors.black.withAlpha(60));
      canvas.drawCircle(c, r * 0.75, Paint()..color = color);
      canvas.drawCircle(
        c,
        r * 0.75,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // Direction ka teer
      final tip = c + b.dir * (r * 1.25);
      final side = Offset(-b.dir.dy, b.dir.dx);
      final arrow = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(c.dx + b.dir.dx * r * 0.8 + side.dx * r * 0.35, c.dy + b.dir.dy * r * 0.8 + side.dy * r * 0.35)
        ..lineTo(c.dx + b.dir.dx * r * 0.8 - side.dx * r * 0.35, c.dy + b.dir.dy * r * 0.8 - side.dy * r * 0.35)
        ..close();
      canvas.drawPath(arrow, Paint()..color = AppColors.ink);
    }

    // Score bar: arena ke upar aur neeche
    _drawScoreBar(canvas, Rect.fromLTWH(0, 0, size.width, 8));
    _drawScoreBar(canvas, Rect.fromLTWH(0, size.height - 8, size.width, 8));

    // Timer: beech mein, dono taraf se parhne ke liye
    final t = g.timeLeft.ceil().toString();
    final timerColor = g.timeLeft <= 5 ? const Color(0xFFD7263D) : AppColors.ink.withAlpha(90);
    _drawText(canvas, t, Offset(size.width / 2, size.height / 2 + 30), 44, timerColor);
    _drawText(canvas, t, Offset(size.width / 2, size.height / 2 - 30), 44, timerColor, flip: true);
  }

  void _drawScoreBar(Canvas canvas, Rect rect) {
    final total = PaintEngine.cols * g.rows;
    canvas.drawRect(rect, Paint()..color = Colors.black.withAlpha(30));
    if (total == 0) return;
    double x = rect.left;
    for (int i = 0; i < g.playerCount; i++) {
      final w = rect.width * g.counts[i] / total;
      canvas.drawRect(Rect.fromLTWH(x, rect.top, w, rect.height), Paint()..color = kPlayers[i].color);
      x += w;
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize, Color color,
      {bool flip = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (flip) canvas.rotate(pi);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PaintPainter oldDelegate) => false;
}
