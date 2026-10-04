import 'package:flutter/material.dart';

/// Har mini game is class ko implement karti hai.
///
/// Arena ke coordinates "normalized" hain: chaurai (width) hamesha 1.0 hai
/// aur unchai (height) = aspect (arena ki height / width). Is tarah game har
/// phone size par aik jaisi chalti hai.
abstract class GameEngine {
  GameEngine(this.playerCount);

  final int playerCount;

  /// Naya round shuru karo. [aspect] = arena height / arena width.
  void setup(double aspect);

  /// Game ko [dt] seconds aage chalao.
  void update(double dt);

  /// Kya round khatam ho gaya?
  bool get roundOver;

  /// Jeetne wale players (khali list = draw).
  List<int> get winners;

  /// Result screen par extra maloomat (masalan paint ka percentage).
  String? get resultDetail => null;

  /// Arena draw karne wala painter. [repaint] har frame par badalta hai.
  CustomPainter createPainter(Listenable repaint);

  /// Player [playerIndex] ke controls (unki patti ke andar).
  Widget buildControls(BuildContext context, int playerIndex);
}
