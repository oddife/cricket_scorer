import 'dart:io';

import 'package:flutter/material.dart';

class TournamentLogo extends StatelessWidget {
  const TournamentLogo({
    super.key,
    required this.tournamentName,
    this.logoPath,
    this.radius = 28,
  });

  final String tournamentName;
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
      child: Text(
        tournamentName.isEmpty ? '?' : tournamentName[0].toUpperCase(),
      ),
    );
  }
}
