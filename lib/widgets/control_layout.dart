import 'package:flutter/material.dart';

/// Arena ko beech mein aur players ke controls ko upar/neeche rakhta hai.
/// Upar wale players ke controls 180° ghoome hote hain taake saamne baitha
/// dost unhein seedha dekh sake.
class PlayerControlsLayout extends StatelessWidget {
  const PlayerControlsLayout({
    super.key,
    required this.playerCount,
    required this.arena,
    required this.zoneBuilder,
    this.stripHeight = 132,
  });

  final int playerCount;
  final Widget arena;
  final Widget Function(int playerIndex) zoneBuilder;
  final double stripHeight;

  Widget _zone(int index, {required bool flipped}) {
    final child = zoneBuilder(index);
    return Expanded(
      child: flipped ? RotatedBox(quarterTurns: 2, child: child) : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = <Widget>[
      if (playerCount >= 4) _zone(3, flipped: true),
      _zone(1, flipped: true),
    ];
    final bottom = <Widget>[
      _zone(0, flipped: false),
      if (playerCount >= 3) _zone(2, flipped: false),
    ];

    return Column(
      children: [
        SizedBox(
          height: stripHeight,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: top),
        ),
        Expanded(child: arena),
        SizedBox(
          height: stripHeight,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: bottom),
        ),
      ],
    );
  }
}
