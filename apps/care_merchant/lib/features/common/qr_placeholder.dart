import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A real, camera-readable QR code containing the booking-bound safety token.
class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({super.key, required this.value, this.size = 200});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: QrImageView(
      data: value,
      size: size - 24,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    ),
  );
}
