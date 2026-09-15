import 'dart:io';

import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    required this.teamName,
    this.logoPath,
    this.radius = 24,
  });

  final String teamName;
  final String? logoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = logoPath?.trim();
    if (path != null && path.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(teamName.isEmpty ? '?' : teamName[0].toUpperCase()),
    );
  }
}
