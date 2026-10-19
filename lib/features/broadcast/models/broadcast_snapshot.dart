enum BroadcastScoringSource {
  androidSync,
  windowsLocal,
  unknown,
}

extension BroadcastScoringSourceJson on BroadcastScoringSource {
  String get wireValue => switch (this) {
        BroadcastScoringSource.androidSync => 'android_sync',
        BroadcastScoringSource.windowsLocal => 'windows_local',
        BroadcastScoringSource.unknown => 'unknown',
      };
}

/// A display-ready snapshot supplied by the existing scoring/recalculation
/// layer. This contract formats data but never recalculates cricket rules.
class BroadcastSnapshot {
  BroadcastSnapshot({
    this.ready = false,
    this.matchId,
    this.matchName,
    this.teamAName,
    this.teamBName,
    this.battingTeamName,
    this.bowlingTeamName,
    this.inningsNumber = 0,
    this.runs = 0,
    this.wickets = 0,
    this.totalLegalBalls = 0,
    this.ballsPerOver = 6,
    this.target,
    this.runsRequired,
    this.ballsRemaining,
    this.runRate,
    this.requiredRunRate,
    this.matchStatus = 'unknown',
    this.scoringSource = BroadcastScoringSource.unknown,
    required this.capturedAt,
    this.lastSyncAt,
    List<BroadcastBatterLine> batters = const [],
    this.bowler,
    List<BroadcastDelivery> currentOver = const [],
    List<BroadcastDelivery> recentDeliveries = const [],
  })  : batters = List.unmodifiable(batters),
        currentOver = List.unmodifiable(currentOver),
        recentDeliveries = List.unmodifiable(recentDeliveries) {
    if (ballsPerOver < 1) {
      throw ArgumentError.value(ballsPerOver, 'ballsPerOver', 'Must be positive.');
    }
    if (runs < 0 || wickets < 0 || totalLegalBalls < 0) {
      throw ArgumentError('Runs, wickets, and legal balls cannot be negative.');
    }
  }

  factory BroadcastSnapshot.empty({DateTime? capturedAt}) =>
      BroadcastSnapshot(capturedAt: capturedAt ?? DateTime.now());

  final bool ready;
  final String? matchId;
  final String? matchName;
  final String? teamAName;
  final String? teamBName;
  final String? battingTeamName;
  final String? bowlingTeamName;
  final int inningsNumber;
  final int runs;
  final int wickets;
  final int totalLegalBalls;
  final int ballsPerOver;
  final int? target;
  final int? runsRequired;
  final int? ballsRemaining;
  final double? runRate;
  final double? requiredRunRate;
  final String matchStatus;
  final BroadcastScoringSource scoringSource;
  final DateTime capturedAt;
  final DateTime? lastSyncAt;
  final List<BroadcastBatterLine> batters;
  final BroadcastBowlerLine? bowler;
  final List<BroadcastDelivery> currentOver;
  final List<BroadcastDelivery> recentDeliveries;

  String get oversText =>
      '${totalLegalBalls ~/ ballsPerOver}.${totalLegalBalls % ballsPerOver}';

  Map<String, Object?> toJson() => {
        'ready': ready,
        'matchId': matchId,
        'matchName': matchName,
        'teamAName': teamAName,
        'teamBName': teamBName,
        'battingTeamName': battingTeamName,
        'bowlingTeamName': bowlingTeamName,
        'inningsNumber': inningsNumber,
        'runs': runs,
        'wickets': wickets,
        'totalLegalBalls': totalLegalBalls,
        'ballsPerOver': ballsPerOver,
        'oversText': oversText,
        'target': target,
        'runsRequired': runsRequired,
        'ballsRemaining': ballsRemaining,
        'runRate': runRate,
        'requiredRunRate': requiredRunRate,
        'matchStatus': matchStatus,
        'scoringSource': scoringSource.wireValue,
        'capturedAt': capturedAt.toIso8601String(),
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'batters': batters.map((batter) => batter.toJson()).toList(),
        'bowler': bowler?.toJson(),
        'currentOver': currentOver.map((ball) => ball.toJson()).toList(),
        'recentDeliveries':
            recentDeliveries.map((ball) => ball.toJson()).toList(),
      };
}

class BroadcastBatterLine {
  const BroadcastBatterLine({
    required this.name,
    required this.runs,
    required this.balls,
    this.fours = 0,
    this.sixes = 0,
    this.isOnStrike = false,
    this.strikeRate,
  });

  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOnStrike;
  final double? strikeRate;

  Map<String, Object?> toJson() => {
        'name': name,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'isOnStrike': isOnStrike,
        'strikeRate': strikeRate,
      };
}

class BroadcastBowlerLine {
  const BroadcastBowlerLine({
    required this.name,
    required this.legalBallsBowled,
    required this.runsConceded,
    required this.wickets,
    this.maidens = 0,
    this.economyRate,
  });

  final String name;
  final int legalBallsBowled;
  final int runsConceded;
  final int wickets;
  final int maidens;
  final double? economyRate;

  String get oversText =>
      '${legalBallsBowled ~/ 6}.${legalBallsBowled % 6}';

  Map<String, Object?> toJson() => {
        'name': name,
        'legalBallsBowled': legalBallsBowled,
        'oversText': oversText,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'maidens': maidens,
        'economyRate': economyRate,
      };
}

class BroadcastDelivery {
  const BroadcastDelivery({
    required this.label,
    required this.totalRuns,
    required this.isWicket,
    required this.isLegalBall,
  });

  final String label;
  final int totalRuns;
  final bool isWicket;
  final bool isLegalBall;

  Map<String, Object?> toJson() => {
        'label': label,
        'totalRuns': totalRuns,
        'isWicket': isWicket,
        'isLegalBall': isLegalBall,
      };
}
