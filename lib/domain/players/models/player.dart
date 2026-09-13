import '../enums/batting_style.dart';
import '../enums/bowling_style.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.displayName,
    this.photoPath,
    this.jerseyNumber,
    this.battingStyle = BattingStyle.right,
    this.bowlingStyle = BowlingStyle.right,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String displayName;
  final String? photoPath;
  final int? jerseyNumber;
  final BattingStyle battingStyle;
  final BowlingStyle bowlingStyle;
  final bool isActive;

  Player copyWith({
    int? id,
    String? name,
    String? displayName,
    String? photoPath,
    int? jerseyNumber,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    bool? isActive,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      isActive: isActive ?? this.isActive,
    );
  }
}
