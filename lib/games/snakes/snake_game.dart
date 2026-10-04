import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_engine.dart';
import '../../core/players.dart';
import '../../widgets/turn_controls.dart';

/// SNAKES
/// Har snake khud aage chalta rehta hai. Player sirf left/right mudta hai.
/// Kisi snake ke jism, apne jism ya deewar se takraye to out.
/// Aakhir mein jo zinda bache wo jeetta hai. Khana khane se snake lamba hota hai.
class Snake {
  Snake(this.player, this.angle, this.length);

  final int player;
  double angle; // radians, 0 = right, pi/2 = neeche
  double length; // jism ki lambai (arena units)
  bool alive = true;

  /// Jism ke points: pehla = dum (tail), aakhri = gardan ke paas.
  final List<Offset> body = <Offset>[];

  /// Sar ki asal (smooth) position.
  Offset headPos = Offset.zero;
}

class SnakeEngine extends GameEngine {
  SnakeEngine(super.playerCount);

  static const double radius = 0.02; // snake ki motai ka aadha
  static const double spacing = 0.008; // jism ke points ka faasla
  static const double baseSpeed = 0.2; // arena-chaurai fi second
  static const double turnSpeed = 3.4; // radians fi second
  static const double startLength = 0.22;
  static const double growPerFood = 0.05;
  static const double foodRadius = 0.016;
  static const int foodCount = 4;

  /// Apne sar ke itne qareeb ke points se takraana count nahi hota.
  static const int _selfSkip = 9;

  final Random _rng = Random();
  final List<bool> _leftDown = List<bool>.filled(4, false);
  final List<bool> _rightDown = List<bool>.filled(4, false);

  double height = 1.6;
  List<Snake> snakes = <Snake>[];
  List<Offset> food = <Offset>[];
  double _elapsed = 0;
  bool _over = false;
  List<int> _winners = <int>[];

  @override
  bool get roundOver => _over;

  @override
  List<int> get winners => _winners;

  @override
  void setup(double aspect) {
    height = aspect;
    snakes = [for (int i = 0; i < playerCount; i++) _makeSnake(i)];
    food = [for (int i = 0; i < foodCount; i++) _randomFoodPos()];
    _elapsed = 0;
    _over = false;
    _winners = <int>[];
  }

  Snake _makeSnake(int i) {
    final top = isTopPlayer(i);
    final x = spawnX(i, playerCount);
    final headY = top ? 0.3 : height - 0.3;
    final s = Snake(i, top ? pi / 2 : -pi / 2, startLength);
    final tailDir = top ? -1.0 : 1.0;
    final n = (startLength / spacing).round();
    for (int k = n; k >= 0; k--) {
      s.body.add(Offset(x, headY + tailDir * k * spacing));
    }
    s.headPos = s.body.last;
    return s;
  }

  Offset _randomFoodPos() {
    const m = 0.07;
    return Offset(
      m + _rng.nextDouble() * (1 - 2 * m),
      m + _rng.nextDouble() * (height - 2 * m),
    );
  }

  @override
  void update(double dt) {
    if (_over) return;
    _elapsed += dt;
    // Waqt ke saath raftaar thori barhti hai (1 minute mein 60% tak)
    final speed = baseSpeed * (1 + min(_elapsed, 60.0) / 60.0 * 0.6);

    // 1) Har zinda snake ko aage chalao
    for (final s in snakes) {
      if (!s.alive) continue;
      final double turn = (_rightDown[s.player] ? 1.0 : 0.0) - (_leftDown[s.player] ? 1.0 : 0.0);
      s.angle += turn * turnSpeed * dt;
      s.headPos += Offset(cos(s.angle), sin(s.angle)) * (speed * dt);

      while ((s.headPos - s.body.last).distance >= spacing) {
        final last = s.body.last;
        final d = s.headPos - last;
        s.body.add(last + d / d.distance * spacing);
      }
      final maxPoints = (s.length / spacing).round();
      if (s.body.length > maxPoints) {
        s.body.removeRange(0, s.body.length - maxPoints);
      }
    }

    // 2) Khana
    for (final s in snakes) {
      if (!s.alive) continue;
      for (int f = 0; f < food.length; f++) {
        if ((food[f] - s.headPos).distance < radius + foodRadius) {
          s.length += growPerFood;
          food[f] = _randomFoodPos();
          HapticFeedback.selectionClick();
        }
      }
    }

    // 3) Takkar check (sab ki aik saath, taake insaaf ho)
    const minD = radius * 1.7;
    const minD2 = minD * minD;
    final dead = <Snake>[];
    for (final s in snakes) {
      if (!s.alive) continue;
      final h = s.headPos;
      if (h.dx < radius || h.dx > 1 - radius || h.dy < radius || h.dy > height - radius) {
        dead.add(s);
        continue;
      }
      bool hit = false;
      for (final o in snakes) {
        if (!o.alive) continue;
        final pts = o.body;
        final limit = identical(o, s) ? pts.length - _selfSkip : pts.length;
        for (int k = 0; k < limit; k++) {
          final dx = pts[k].dx - h.dx;
          final dy = pts[k].dy - h.dy;
          if (dx * dx + dy * dy < minD2) {
            hit = true;
            break;
          }
        }
        if (!hit && !identical(o, s)) {
          if ((o.headPos - h).distance < minD) hit = true;
        }
        if (hit) break;
      }
      if (hit) dead.add(s);
    }
    if (dead.isNotEmpty) {
      for (final s in dead) {
        s.alive = false;
      }
      HapticFeedback.heavyImpact();
    }

    // 4) Round khatam?
    final alive = snakes.where((s) => s.alive).toList();
    if (alive.length <= 1) {
      _over = true;
      _winners = alive.map((s) => s.player).toList();
    }
  }

  @override
  CustomPainter createPainter(Listenable repaint) => _SnakePainter(this, repaint);

  @override
  Widget buildControls(BuildContext context, int playerIndex) {
    return TurnControls(
      player: kPlayers[playerIndex],
      onLeft: (down) => _leftDown[playerIndex] = down,
      onRight: (down) => _rightDown[playerIndex] = down,
    );
  }
}

class _SnakePainter extends CustomPainter {
  _SnakePainter(this.g, Listenable repaint) : super(repaint: repaint);

  final SnakeEngine g;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Zameen
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.table);
    final grid = Paint()
      ..color = AppColors.tableLine
      ..strokeWidth = 1;
    for (double x = 0.1; x < 1.0; x += 0.1) {
      canvas.drawLine(Offset(x * s, 0), Offset(x * s, size.height), grid);
    }
    for (double y = 0.1; y < g.height; y += 0.1) {
      canvas.drawLine(Offset(0, y * s), Offset(size.width, y * s), grid);
    }
    canvas.drawRect(
      (Offset.zero & size).deflate(1.5),
      Paint()
        ..color = Colors.white.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Khana
    final foodGlow = Paint()..color = Colors.white.withAlpha(50);
    final foodPaint = Paint()..color = Colors.white;
    for (final f in g.food) {
      canvas.drawCircle(f * s, SnakeEngine.foodRadius * s * 1.8, foodGlow);
      canvas.drawCircle(f * s, SnakeEngine.foodRadius * s, foodPaint);
    }

    // Pehle mare hue snakes (halke), phir zinda
    for (final sn in g.snakes.where((x) => !x.alive)) {
      _drawSnake(canvas, s, sn);
    }
    for (final sn in g.snakes.where((x) => x.alive)) {
      _drawSnake(canvas, s, sn);
    }
  }

  void _drawSnake(Canvas canvas, double s, Snake sn) {
    if (sn.body.isEmpty) return;
    final base = kPlayers[sn.player].color;
    final color = sn.alive ? base : base.withAlpha(70);
    final r = SnakeEngine.radius * s;

    final path = Path()..moveTo(sn.body.first.dx * s, sn.body.first.dy * s);
    for (int i = 1; i < sn.body.length; i++) {
      path.lineTo(sn.body[i].dx * s, sn.body[i].dy * s);
    }
    path.lineTo(sn.headPos.dx * s, sn.headPos.dy * s);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sar
    final h = sn.headPos * s;
    canvas.drawCircle(h, r * 1.2, Paint()..color = color);
    if (!sn.alive) return;

    // Aankhein
    final dir = Offset(cos(sn.angle), sin(sn.angle));
    final side = Offset(-dir.dy, dir.dx);
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = AppColors.ink;
    for (final sign in const [-1.0, 1.0]) {
      final eye = h + dir * (r * 0.45) + side * (r * 0.55 * sign);
      canvas.drawCircle(eye, r * 0.4, white);
      canvas.drawCircle(eye + dir * (r * 0.15), r * 0.2, black);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => false;
}
