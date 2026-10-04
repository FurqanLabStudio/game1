import 'package:flutter/material.dart';

import '../core/players.dart';

/// Do bade buttons: daba kar rakho to snake us taraf mudta rehta hai.
class TurnControls extends StatelessWidget {
  const TurnControls({
    super.key,
    required this.player,
    required this.onLeft,
    required this.onRight,
  });

  final PlayerInfo player;
  final ValueChanged<bool> onLeft;
  final ValueChanged<bool> onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: player.color.withAlpha(36),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlayerTag(player: player),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: HoldButton(
                    color: player.color,
                    iconColor: player.onColor,
                    icon: Icons.rotate_left_rounded,
                    onChanged: onLeft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HoldButton(
                    color: player.color,
                    iconColor: player.onColor,
                    icon: Icons.rotate_right_rounded,
                    onChanged: onRight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aisa button jo dabane par `true` aur chhorne par `false` bhejta hai.
/// Listener use kiya hai taake kayi ungliyan aik saath kaam karein.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onChanged,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  int _pointers = 0;

  void _down(PointerEvent e) {
    _pointers++;
    if (_pointers == 1) {
      setState(() {});
      widget.onChanged(true);
    }
  }

  void _up(PointerEvent e) {
    if (_pointers > 0) _pointers--;
    if (_pointers == 0) {
      setState(() {});
      widget.onChanged(false);
    }
  }

  @override
  void dispose() {
    if (_pointers > 0) widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pointers > 0;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        decoration: BoxDecoration(
          color: pressed ? widget.color : widget.color.withAlpha(120),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.color, width: 2),
        ),
        child: Center(
          child: Icon(widget.icon, size: 44, color: widget.iconColor),
        ),
      ),
    );
  }
}

class _PlayerTag extends StatelessWidget {
  const _PlayerTag({required this.player});

  final PlayerInfo player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: player.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${player.shortName}  ${player.name}',
          style: TextStyle(
            color: player.color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Doosri jagah bhi player tag chahiye ho to.
class PlayerTag extends StatelessWidget {
  const PlayerTag({super.key, required this.player});

  final PlayerInfo player;

  @override
  Widget build(BuildContext context) => _PlayerTag(player: player);
}
