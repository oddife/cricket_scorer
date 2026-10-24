import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/models/match_player.dart';
import '../../../domain/matches/models/match_team.dart';
import '../../../domain/players/models/player.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/enums/wicket_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import '../../../domain/teams/models/team.dart';
import '../models/broadcast_snapshot.dart';

/// Maps the app's already-recalculated cricket state to display-only data.
///
/// This class deliberately performs no scoring or match-result calculations.
class BroadcastSnapshotBuilder {
  const BroadcastSnapshotBuilder._();

  static BroadcastSnapshot build({
    required Match match,
    required Innings innings,
    required InningsState score,
    required int strikerId,
    required int nonStrikerId,
    int? selectedBowlerId,
    required List<MatchTeam> matchTeams,
    required List<Team> teams,
    required List<MatchPlayer> matchPlayers,
    required List<Player> players,
    required List<BallEvent> events,
    int? target,
    BroadcastScoringSource scoringSource = BroadcastScoringSource.unknown,
    DateTime? lastSyncAt,
    DateTime? capturedAt,
    bool automaticEventsEligible = false,
  }) {
    final teamById = <int, Team>{for (final team in teams) team.id: team};
    final playerById = <int, Player>{for (final player in players) player.id: player};
    final matchPlayerIds = matchPlayers.map((player) => player.playerId).toSet();

    String playerName(int id) {
      final player = playerById[id];
      if (player == null || !matchPlayerIds.contains(id)) {
        return 'Unknown Player';
      }
      final displayName = player.displayName.trim();
      return displayName.isNotEmpty ? displayName : player.name;
    }

    String teamName(int id) => teamById[id]?.name ?? 'Team $id';

    int? teamIdForSlot(MatchTeamSlot slot) {
      for (final matchTeam in matchTeams) {
        if (matchTeam.slot == slot) return matchTeam.teamId;
      }
      return null;
    }

    final teamAId = teamIdForSlot(MatchTeamSlot.teamA);
    final teamBId = teamIdForSlot(MatchTeamSlot.teamB);
    final orderedEvents = List<BallEvent>.of(events)
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    final latestOverNumber =
        orderedEvents.isEmpty ? null : orderedEvents.last.overNumber;
    final currentOverEvents = latestOverNumber == null
        ? const <BallEvent>[]
        : orderedEvents
            .where((event) => event.overNumber == latestOverNumber)
            .toList(growable: false);
    final recentEvents = orderedEvents.length <= 6
        ? orderedEvents
        : orderedEvents.sublist(orderedEvents.length - 6);

    void addUnique(List<int> ids, int id) {
      if (id > 0 && !ids.contains(id)) ids.add(id);
    }

    String dismissalText(BallEvent event) {
      final wicket = event.wicket!;
      final bowler = playerName(event.bowlerId);
      final fielder = wicket.fielderId == null
          ? null
          : playerName(wicket.fielderId!);
      return switch (wicket.type) {
        WicketType.bowled => 'b $bowler',
        WicketType.caught =>
          fielder == null ? 'c b $bowler' : 'c $fielder b $bowler',
        WicketType.lbw => 'lbw b $bowler',
        WicketType.runOut =>
          fielder == null ? 'run out' : 'run out ($fielder)',
        WicketType.stumped =>
          fielder == null ? 'st b $bowler' : 'st $fielder b $bowler',
        WicketType.hitWicket => 'hit wicket b $bowler',
        WicketType.retired => 'retired',
        WicketType.obstructingField => 'obstructing the field',
        WicketType.overFence => 'over fence',
      };
    }

    final latestScoringEvent =
        orderedEvents.isEmpty ? null : orderedEvents.last;
    final latestScoringEventKind = latestScoringEvent == null
        ? null
        : _scoringEventKind(latestScoringEvent);
    final scoringContextIdentity = '${match.id}/${innings.id}';
    final activeScoringEventIdentities = orderedEvents
        .map((event) => '${match.id}/${innings.id}/${event.id}')
        .toSet();
    final scoringEventCandidates = orderedEvents
        .map((event) {
          final kind = _scoringEventKind(event);
          if (kind == null) return null;
          return BroadcastScoringEvent(
            identity: '${match.id}/${innings.id}/${event.id}',
            kind: kind,
            detail: playerName(event.strikerId),
          );
        })
        .whereType<BroadcastScoringEvent>()
        .toList(growable: false);
    final latestScoringEventIdentity = latestScoringEvent == null
        ? null
        : '${match.id}/${innings.id}/${latestScoringEvent.id}';

    final battingRoster = matchPlayers
        .where((player) =>
            player.teamId == innings.battingTeamId && player.isPlaying)
        .toList()
      ..sort((a, b) {
        final orderA = a.battingOrder;
        final orderB = b.battingOrder;
        if (orderA != null && orderB != null) return orderA.compareTo(orderB);
        if (orderA != null) return -1;
        if (orderB != null) return 1;
        return a.id.compareTo(b.id);
      });

    final fullBattingIds = <int>[];
    final hasBattingOrder = battingRoster.any((player) => player.battingOrder != null);
    if (hasBattingOrder) {
      for (final player in battingRoster) {
        addUnique(fullBattingIds, player.playerId);
      }
    } else {
      addUnique(fullBattingIds, innings.openingStrikerId);
      addUnique(fullBattingIds, innings.openingNonStrikerId);
      for (final event in orderedEvents) {
        addUnique(fullBattingIds, event.strikerId);
        addUnique(fullBattingIds, event.nonStrikerId);
      }
      for (final player in battingRoster) {
        addUnique(fullBattingIds, player.playerId);
      }
    }
    for (final id in score.batters.keys) {
      addUnique(fullBattingIds, id);
    }

    final fullBattingScorecard = fullBattingIds.map((id) {
      final batting = score.batters[id];
      final dismissalEvent = orderedEvents.reversed
          .where((event) => event.wicket?.dismissedPlayerId == id)
          .firstOrNull;
      final balls = batting?.balls ?? 0;
      final runs = batting?.runs ?? 0;
      return BroadcastFullBattingRow(
        name: playerName(id),
        dismissal: dismissalEvent == null
            ? (batting == null ? 'Did not bat' : null)
            : dismissalText(dismissalEvent),
        runs: runs,
        balls: balls,
        fours: batting?.fours ?? 0,
        sixes: batting?.sixes ?? 0,
        strikeRate: balls == 0 ? null : runs * 100 / balls,
        didNotBat: batting == null,
        isOut: batting?.isOut ?? dismissalEvent != null,
      );
    }).toList(growable: false);

    final fullBowlerIds = <int>[];
    addUnique(fullBowlerIds, innings.openingBowlerId);
    for (final event in orderedEvents) {
      addUnique(fullBowlerIds, event.bowlerId);
    }
    final remainingBowlers = score.bowlers.keys
        .where((id) => !fullBowlerIds.contains(id))
        .toList()
      ..sort();
    fullBowlerIds.addAll(remainingBowlers);
    final fullBowlingScorecard = fullBowlerIds.map((id) {
      final figures = score.bowlers[id];
      final legalBalls = figures?.legalBalls ?? 0;
      final runsConceded = figures?.runsConceded ?? 0;
      return BroadcastFullBowlingRow(
        name: playerName(id),
        legalBallsBowled: legalBalls,
        ballsPerOver: innings.ballsPerOver,
        maidens: null,
        runsConceded: runsConceded,
        wickets: figures?.wickets ?? 0,
        economyRate: legalBalls == 0
            ? null
            : runsConceded * innings.ballsPerOver / legalBalls,
      );
    }).toList(growable: false);

    final playingXiTeams = <BroadcastPlayingXiTeam>[];
    for (final teamId in [teamAId, teamBId].whereType<int>()) {
      final selectedPlayers = matchPlayers
          .where((player) => player.teamId == teamId && player.isPlaying)
          .toList()
        ..sort((a, b) {
          final orderA = a.battingOrder;
          final orderB = b.battingOrder;
          if (orderA != null && orderB != null) return orderA.compareTo(orderB);
          if (orderA != null) return -1;
          if (orderB != null) return 1;
          return a.id.compareTo(b.id);
        });
      playingXiTeams.add(BroadcastPlayingXiTeam(
        teamId: teamId,
        name: teamName(teamId),
        players: selectedPlayers
            .take(11)
            .map((player) => playerName(player.playerId))
            .toList(growable: false),
      ));
    }

    final batterIds = <int>[];
    for (final id in [strikerId, nonStrikerId]) {
      if (id > 0 && !batterIds.contains(id)) batterIds.add(id);
    }
    final batters = <BroadcastBatterLine>[];
    for (final id in batterIds) {
      final batting = score.batters[id];
      final runs = batting?.runs ?? 0;
      final balls = batting?.balls ?? 0;
      batters.add(BroadcastBatterLine(
        name: playerName(id),
        runs: runs,
        balls: balls,
        fours: batting?.fours ?? 0,
        sixes: batting?.sixes ?? 0,
        isOnStrike: id == strikerId,
        strikeRate: balls == 0 ? null : runs * 100 / balls,
      ));
    }

    final effectiveBowlerId = score.bowlerId > 0
        ? score.bowlerId
        : selectedBowlerId ?? innings.openingBowlerId;
    final bowlerStats = effectiveBowlerId > 0
        ? score.bowlers[effectiveBowlerId]
        : null;
    final bowler = effectiveBowlerId <= 0
        ? null
        : BroadcastBowlerLine(
            name: playerName(effectiveBowlerId),
            legalBallsBowled: bowlerStats?.legalBalls ?? 0,
            runsConceded: bowlerStats?.runsConceded ?? 0,
            wickets: bowlerStats?.wickets ?? 0,
            economyRate: (bowlerStats?.legalBalls ?? 0) == 0
                ? null
                : (bowlerStats!.runsConceded *
                    innings.ballsPerOver /
                    bowlerStats.legalBalls),
          );

    final ballsRemaining = (innings.oversPerInnings * innings.ballsPerOver -
            score.legalBalls)
        .clamp(0, innings.oversPerInnings * innings.ballsPerOver)
        .toInt();
    final runsRequired = target == null
        ? null
        : (target - score.score).clamp(0, target).toInt();
    final runRate = score.legalBalls == 0
        ? null
        : score.score * innings.ballsPerOver / score.legalBalls;
    final requiredRunRate = runsRequired == null || ballsRemaining == 0
        ? null
        : runsRequired * innings.ballsPerOver / ballsRemaining;

    return BroadcastSnapshot(
      ready: true,
      matchId: match.id.toString(),
      matchName: match.name,
      teamAName: teamAId == null ? 'Team A' : teamName(teamAId),
      teamBName: teamBId == null ? 'Team B' : teamName(teamBId),
      battingTeamName: teamName(innings.battingTeamId),
      bowlingTeamName: teamName(innings.bowlingTeamId),
      inningsNumber: innings.inningsNumber,
      runs: score.score,
      wickets: score.wickets,
      totalLegalBalls: score.legalBalls,
      ballsPerOver: innings.ballsPerOver,
      target: target,
      runsRequired: runsRequired,
      ballsRemaining: ballsRemaining,
      runRate: runRate,
      requiredRunRate: requiredRunRate,
      matchStatus: match.status.label,
      scoringSource: scoringSource,
      capturedAt: capturedAt ?? DateTime.now(),
      lastSyncAt: lastSyncAt,
      scoringContextIdentity: scoringContextIdentity,
      latestScoringEventIdentity: latestScoringEventIdentity,
      latestScoringEventKind: latestScoringEventKind,
      latestScoringEventDetail: latestScoringEventKind == null ||
              latestScoringEvent == null
          ? null
          : playerName(latestScoringEvent.strikerId),
      automaticEventsEligible: automaticEventsEligible,
      activeScoringEventIdentities: activeScoringEventIdentities,
      scoringEventCandidates: scoringEventCandidates,
      batters: batters,
      fullBattingScorecard: fullBattingScorecard,
      fullBowlingScorecard: fullBowlingScorecard,
      playingXiTeams: playingXiTeams,
      extras: score.wides + score.noBalls + score.byes + score.legByes,
      wides: score.wides,
      noBalls: score.noBalls,
      byes: score.byes,
      legByes: score.legByes,
      bowler: bowler,
      currentOver: currentOverEvents
          .map(_toBroadcastDelivery)
          .toList(growable: false),
      recentDeliveries:
          recentEvents.map(_toBroadcastDelivery).toList(growable: false),
    );
  }

  static String? _scoringEventKind(BallEvent event) {
    if (event.hasWicket) return 'WICKET';
    if (event.batterRuns == 4) return 'FOUR';
    if (event.batterRuns == 6) return 'SIX';
    return null;
  }

  static BroadcastDelivery _toBroadcastDelivery(BallEvent event) {
    final label = _deliveryLabel(event);
    return BroadcastDelivery(
      label: label,
      totalRuns: event.totalRuns,
      isWicket: event.hasWicket,
      isLegalBall: event.isLegalBall,
    );
  }

  static String _deliveryLabel(BallEvent event) {
    final String label;
    switch (event.deliveryType) {
      case DeliveryType.normal:
        label = event.batterRuns == 0 ? '•' : event.batterRuns.toString();
        break;
      case DeliveryType.wide:
        label = event.wideRuns > 1 ? 'Wd+${event.wideRuns - 1}' : 'Wd';
        break;
      case DeliveryType.noBall:
        label = event.batterRuns > 0 ? 'Nb+${event.batterRuns}' : 'Nb';
        break;
      case DeliveryType.bye:
        label = 'B${event.byeRuns}';
        break;
      case DeliveryType.legBye:
        label = 'Lb${event.legByeRuns}';
        break;
    }

    if (!event.hasWicket) return label;
    return event.totalRuns == 0 ? 'W' : '${label}W';
  }
}
