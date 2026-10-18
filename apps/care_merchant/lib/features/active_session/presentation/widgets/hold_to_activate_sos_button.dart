import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HoldToActivateSosButton extends StatefulWidget {
  final VoidCallback onSosTriggered;

  const HoldToActivateSosButton({
    super.key,
    required this.onSosTriggered,
  });

  @override
  State<HoldToActivateSosButton> createState() =>
      _HoldToActivateSosButtonState();
}

class _HoldToActivateSosButtonState extends State<HoldToActivateSosButton> {
  Timer? _holdTimer;
  double _progress = 0.0;
  static const int _holdDurationMs = 2000;
  static const int _updateIntervalMs = 50;

  void _startHolding() {
    setState(() => _progress = 0.0);
    _holdTimer?.cancel();

    int elapsedMs = 0;
    _holdTimer = Timer.periodic(
      const Duration(milliseconds: _updateIntervalMs),
      (timer) {
        elapsedMs += _updateIntervalMs;
        setState(() {
          _progress = (elapsedMs / _holdDurationMs).clamp(0.0, 1.0);
        });

        if (elapsedMs >= _holdDurationMs) {
          timer.cancel();
          widget.onSosTriggered();
        }
      },
    );
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    setState(() => _progress = 0.0);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: () => _stopHolding(),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.emergencyRed.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.emergencyRed, width: 2),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Progress Fill
            FractionallySizedBox(
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _progress > 0.5 ? Colors.white : AppColors.emergencyRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _progress > 0
                        ? 'HOLDING... (${((1 - _progress) * 2).toStringAsFixed(1)}s)'
                        : 'HOLD FOR EMERGENCY SOS (2s)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _progress > 0.5 ? Colors.white : AppColors.emergencyRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
