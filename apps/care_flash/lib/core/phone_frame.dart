import 'package:flutter/material.dart';

/// Frames the app as a phone on wide windows (web/desktop) so the mobile
/// layout and its aspect ratio are preserved for the two-window demo, and
/// passes the app straight through on a phone-sized window.
///
/// Applied from `MaterialApp.router`'s `builder`, so the framed area sees the
/// phone's logical size through the overridden [MediaQuery].
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, required this.label});

  final Widget child;

  /// Small caption drawn above the phone, e.g. "Care-Flash".
  final String label;

  static const double _screenWidth = 390;
  static const double _screenHeight = 844;
  static const double _bezel = 12;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final fitsPhone = size.width <= _screenWidth + 2 * _bezel + 24 &&
        size.height <= _screenHeight + 2 * _bezel + 24;
    if (fitsPhone) return child;

    return ColoredBox(
      color: const Color(0xFF0B0F14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: _screenWidth + 2 * _bezel,
                height: _screenHeight + 2 * _bezel,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(_bezel),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: MediaQuery(
                    data: media.copyWith(
                      size: const Size(_screenWidth, _screenHeight),
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
