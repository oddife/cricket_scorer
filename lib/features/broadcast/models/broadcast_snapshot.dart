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
    this.scoringContextIdentity,
    this.latestScoringEventIdentity,
    this.latestScoringEventKind,
    this.latestScoringEventDetail,
    this.automaticEventsEligible = false,
    Set<String> activeScoringEventIdentities = const <String>{},
    List<BroadcastScoringEvent> scoringEventCandidates = const [],
    List<BroadcastBatterLine> batters = const [],
    List<BroadcastFullBattingRow> fullBattingScorecard = const [],
    List<BroadcastFullBowlingRow> fullBowlingScorecard = const [],
    List<BroadcastPlayingXiTeam> playingXiTeams = const [],
    this.extras = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.bowler,
    List<BroadcastDelivery> currentOver = const [],
    List<BroadcastDelivery> recentDeliveries = const [],
  })  : activeScoringEventIdentities =
            Set<String>.unmodifiable(activeScoringEventIdentities),
        scoringEventCandidates = List.unmodifiable(scoringEventCandidates),
        batters = List.unmodifiable(batters),
        fullBattingScorecard = List.unmodifiable(fullBattingScorecard),
        fullBowlingScorecard = List.unmodifiable(fullBowlingScorecard),
        playingXiTeams = List.unmodifiable(playingXiTeams),
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
  final String? scoringContextIdentity;
  final String? latestScoringEventIdentity;
  final String? latestScoringEventKind;
  final String? latestScoringEventDetail;
  final bool automaticEventsEligible;
  final Set<String> activeScoringEventIdentities;
  final List<BroadcastScoringEvent> scoringEventCandidates;
  final List<BroadcastBatterLine> batters;
  final List<BroadcastFullBattingRow> fullBattingScorecard;
  final List<BroadcastFullBowlingRow> fullBowlingScorecard;
  final List<BroadcastPlayingXiTeam> playingXiTeams;
  final int extras;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
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
        'scoringContextIdentity': scoringContextIdentity,
        'latestScoringEventIdentity': latestScoringEventIdentity,
        'latestScoringEventKind': latestScoringEventKind,
        'latestScoringEventDetail': latestScoringEventDetail,
        'automaticEventsEligible': automaticEventsEligible,
        'activeScoringEventIdentities':
            activeScoringEventIdentities.toList()..sort(),
        'scoringEventCandidates':
            scoringEventCandidates.map((event) => event.toJson()).toList(),
        'batters': batters.map((batter) => batter.toJson()).toList(),
        'fullBattingScorecard':
            fullBattingScorecard.map((row) => row.toJson()).toList(),
        'fullBowlingScorecard':
            fullBowlingScorecard.map((row) => row.toJson()).toList(),
        'playingXiTeams': playingXiTeams.map((team) => team.toJson()).toList(),
        'extras': extras,
        'wides': wides,
        'noBalls': noBalls,
        'byes': byes,
        'legByes': legByes,
        'bowler': bowler?.toJson(),
        'currentOver': currentOver.map((ball) => ball.toJson()).toList(),
        'recentDeliveries':
            recentDeliveries.map((ball) => ball.toJson()).toList(),
      };
}


class BroadcastFullBattingRow {
  const BroadcastFullBattingRow({
    required this.name,
    this.dismissal,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.strikeRate,
    this.didNotBat = false,
    this.isOut = false,
  });

  final String name;
  final String? dismissal;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double? strikeRate;
  final bool didNotBat;
  final bool isOut;

  Map<String, Object?> toJson() => {
        'name': name,
        'dismissal': dismissal,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'strikeRate': strikeRate,
        'didNotBat': didNotBat,
        'isOut': isOut,
      };
}

class BroadcastFullBowlingRow {
  const BroadcastFullBowlingRow({
    required this.name,
    required this.legalBallsBowled,
    required this.ballsPerOver,
    this.maidens,
    required this.runsConceded,
    required this.wickets,
    this.economyRate,
  });

  final String name;
  final int legalBallsBowled;
  final int ballsPerOver;
  final int? maidens;
  final int runsConceded;
  final int wickets;
  final double? economyRate;

  String get oversText =>
      '${legalBallsBowled ~/ ballsPerOver}.${legalBallsBowled % ballsPerOver}';

  Map<String, Object?> toJson() => {
        'name': name,
        'legalBallsBowled': legalBallsBowled,
        'oversText': oversText,
        'maidens': maidens,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'economyRate': economyRate,
      };
}

class BroadcastPlayingXiTeam {
  BroadcastPlayingXiTeam({
    required this.teamId,
    required this.name,
    required List<String> players,
  }) : players = List.unmodifiable(players);

  final int teamId;
  final String name;
  final List<String> players;

  Map<String, Object?> toJson() => {
        'teamId': teamId,
        'name': name,
        'players': players,
      };
}

class BroadcastScoringEvent {
  const BroadcastScoringEvent({
    required this.identity,
    required this.kind,
    this.detail,
  });

  final String identity;
  final String kind;
  final String? detail;

  Map<String, Object?> toJson() => {
        'identity': identity,
        'kind': kind,
        'detail': detail,
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
