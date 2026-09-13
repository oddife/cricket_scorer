import '../enums/tournament_type.dart';

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.type,
    this.logoPath,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  final int id;
  final String name;
  final TournamentType type;
  final String? logoPath;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
}