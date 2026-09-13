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

  Tournament copyWith({
    int? id,
    String? name,
    TournamentType? type,
    String? logoPath,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoPath: logoPath ?? this.logoPath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}