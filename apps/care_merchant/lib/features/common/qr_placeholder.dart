import 'package:flutter/material.dart';

/// A deterministic, decorative QR-style square for the safety button handover.
///
/// The prototype has no camera, so neither app needs a real encoder. This draws
/// a QR-looking pattern seeded from [value] so each booking shows a stable,
/// distinct code. TODO(team): swap in `qr_flutter` when a real encoder is
/// needed. (FR-CM-15, HI-CM-1)
class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({
    super.key,
    required this.value,
    this.size = 200,
  });

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _QrPainter(
          seed: value.hashCode,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed, required this.color});

  final int seed;
  final Color color;

  static const int _modules = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = color;
    var state = seed == 0 ? 0x9E3779B9 : seed;

    bool nextBit() {
      // A tiny deterministic PRNG so the pattern never changes for one booking.
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return (state >> 16) & 1 == 1;
    }

    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        final finder = _finderValue(x, y);
        final on = finder ?? nextBit();
        if (on) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  /// Returns true/false for a module inside one of the three finder squares, or
  /// null when the module is part of the data area.
  bool? _finderValue(int x, int y) {
    bool within(int ox, int oy) =>
        x >= ox && x < ox + 7 && y >= oy && y < oy + 7;
    (int, int)? origin;
    if (within(0, 0)) {
      origin = (0, 0);
    } else if (within(_modules - 7, 0)) {
      origin = (_modules - 7, 0);
    } else if (within(0, _modules - 7)) {
      origin = (0, _modules - 7);
    }
    if (origin == null) {
      return null;
    }
    final lx = x - origin.$1;
    final ly = y - origin.$2;
    final border = lx == 0 || lx == 6 || ly == 0 || ly == 6;
    final center = lx >= 2 && lx <= 4 && ly >= 2 && ly <= 4;
    return border || center;
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
