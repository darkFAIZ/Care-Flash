import 'dart:convert';

import 'package:flutter/material.dart';
import 'app_text.dart';

/// Round user avatar: the person's photo when we have one, otherwise their
/// initials on a colour picked from their name so the same person always gets
/// the same colour.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.imageUrl,
    this.avatarDataUrl,
    this.heroTag,
  });

  final String name;
  final double radius;
  final String? imageUrl;

  /// A `data:image/...;base64,...` photo, used by the demo profile editor.
  final String? avatarDataUrl;

  /// Wraps the avatar in a [Hero] flight, for example when a matched
  /// caregiver card opens into the full booking screen.
  final String? heroTag;

  ImageProvider? get _image {
    final dataUrl = avatarDataUrl;
    if (dataUrl != null) {
      final comma = dataUrl.indexOf(',');
      if (comma >= 0) {
        try {
          return MemoryImage(base64Decode(dataUrl.substring(comma + 1)));
        } on FormatException {
          // Fall back to initials when the saved photo is corrupt.
        }
      }
    }
    return imageUrl == null ? null : NetworkImage(imageUrl!);
  }

  static const List<Color> _palette = <Color>[
    Color(0xFF0F8B8D),
    Color(0xFF4F46E5),
    Color(0xFF0E7490),
    Color(0xFF7C3AED),
    Color(0xFF0369A1),
    Color(0xFFB45309),
    Color(0xFFBE123C),
    Color(0xFF15803D),
  ];

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first;
    if (parts.length > 1) {
      return '${first[0]}${parts[1][0]}'.toUpperCase();
    }
    return first.substring(0, first.length.clamp(1, 2)).toUpperCase();
  }

  Color get _color => _palette[name.trim().hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final image = _image;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      foregroundColor: Colors.white,
      backgroundImage: image,
      child: image == null
          ? AppText(
              initialsOf(name),
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );
    if (heroTag == null) return avatar;
    return Hero(tag: heroTag!, child: avatar);
  }
}
