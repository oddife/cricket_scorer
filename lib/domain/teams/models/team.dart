class Team {
  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoPath,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String shortName;
  final String? logoPath;
  final bool isActive;

  Team copyWith({
    String? name,
    String? shortName,
    String? logoPath,
    bool? isActive,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoPath: logoPath ?? this.logoPath,
      isActive: isActive ?? this.isActive,
    );
  }
}
