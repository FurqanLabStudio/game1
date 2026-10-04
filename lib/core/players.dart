import 'package:flutter/material.dart';

/// Ek player ki pehchan: number, naam aur rang.
class PlayerInfo {
  final int index; // 0..3
  final String name;
  final Color color;
  final Color onColor; // is rang ke upar text ka rang

  const PlayerInfo(this.index, this.name, this.color, this.onColor);

  String get shortName => 'P${index + 1}';
}

const List<PlayerInfo> kPlayers = [
  PlayerInfo(0, 'Red', Color(0xFFFF4D5E), Colors.white),
  PlayerInfo(1, 'Blue', Color(0xFF3D8BFF), Colors.white),
  PlayerInfo(2, 'Green', Color(0xFF2FD08A), Color(0xFF07291A)),
  PlayerInfo(3, 'Yellow', Color(0xFFFFC93C), Color(0xFF3A2A00)),
];

/// App ke basic rang.
class AppColors {
  static const Color table = Color(0xFF0E3B3D); // game table jaisa gehra teal
  static const Color tableLine = Color(0xFF165052);
  static const Color paper = Color(0xFFEFF3F8);
  static const Color ink = Color(0xFF0A1F20);
}

/// Screen ki layout:
///   upar wali patti  : P4 (left)  | P2 (right)   -> ye ulti (180°) hoti hai
///   neeche wali patti: P1 (left)  | P3 (right)
/// 2 players: P1 neeche, P2 upar. 3 players: P1 | P3 neeche, P2 upar.
bool isTopPlayer(int i) => i == 1 || i == 3;

/// Arena mein player ki shuru ki X position (0..1, arena ki chaurai ke hisaab se).
double spawnX(int i, int playerCount) {
  switch (i) {
    case 0:
      return playerCount >= 3 ? 0.27 : 0.35;
    case 1:
      if (playerCount >= 4) return 0.73;
      if (playerCount == 3) return 0.5;
      return 0.65;
    case 2:
      return 0.73;
    default:
      return 0.27;
  }
}
