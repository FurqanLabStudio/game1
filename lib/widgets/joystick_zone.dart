import 'package:flutter/material.dart';

import '../core/players.dart';
import 'turn_controls.dart';

/// Poori patti joystick hai: jahan ungli rakho wahin joystick ban jata hai,
/// phir jis taraf ghaseeto brush us taraf chalta hai.
///
/// [onChanged] arena ke hisaab se direction bhejta hai (length 0..1).
/// Agar patti ulti (upar wale player ki) hai to [flipped] = true,
/// taake direction sahi ho jaye.
class JoystickZone extends StatefulWidget {
  const JoystickZone({
    super.key,
    required this.player,
    required this.flipped,
    required this.onChanged,
  });

  final PlayerInfo player;
  final bool flipped;
  final ValueChanged<Offset> onChanged;

  @override
  State<JoystickZone> createState() => _JoystickZoneState();
}

class _JoystickZoneState extends State<JoystickZone> {
  static const double _maxR = 42;

  int? _pointer;
  Offset? _origin;
  Offset _knob = Offset.zero;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    setState(() {
      _pointer = e.pointer;
      _origin = e.localPosition;
      _knob = Offset.zero;
    });
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _origin == null) return;
    Offset d = e.localPosition - _origin!;
    final len = d.distance;
    if (len > _maxR) d = d / len * _maxR;
    setState(() => _knob = d);
    final v = d / _maxR;
    widget.onChanged(widget.flipped ? -v : v);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    setState(() {
      _pointer = null;
      _origin = null;
      _knob = Offset.zero;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.color;
    final origin = _origin;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Container(
        color: color.withAlpha(36),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: PlayerTag(player: widget.player)),
            if (origin == null)
              Center(
                child: Container(
                  width: _maxR * 2,
                  height: _maxR * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(140), width: 2),
                  ),
                  child: Icon(Icons.open_with_rounded, color: color.withAlpha(180), size: 34),
                ),
              )
            else
              Positioned(
                left: origin.dx - _maxR - 8,
                top: origin.dy - _maxR - 6,
                child: SizedBox(
                  width: _maxR * 2,
                  height: _maxR * 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(60),
                          border: Border.all(color: color, width: 2),
                        ),
                      ),
                      Positioned(
                        left: _maxR - 20 + _knob.dx,
                        top: _maxR - 20 + _knob.dy,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
