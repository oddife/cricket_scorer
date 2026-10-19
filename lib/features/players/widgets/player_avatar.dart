import 'dart:io';

import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.displayName,
    this.photoPath,
    this.radius = 24,
  });

  final String displayName;
  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = photoPath?.trim();
    if (path != null && path.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
      ),
    );
  }
}
