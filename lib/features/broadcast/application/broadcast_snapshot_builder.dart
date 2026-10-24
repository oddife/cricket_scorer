import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/models/match_player.dart';
import '../../../domain/matches/models/match_team.dart';
import '../../../domain/players/models/player.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
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
