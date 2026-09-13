class Player {
  const Player({
    required this.id,
    required this.name,
    required this.displayName,
    this.photoPath,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String displayName;
  final String? photoPath;
  final bool isActive;

  Player copyWith({
    int? id,
    String? name,
    String? displayName,
    String? photoPath,
    bool? isActive,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
    );
  }
}
