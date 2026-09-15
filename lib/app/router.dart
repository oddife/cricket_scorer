import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/home_screen.dart';
import '../features/management/screens/settings_screen.dart';
import '../features/players/screens/player_list_screen.dart';
import '../features/players/screens/player_profile_screen.dart';
import '../features/teams/screens/team_detail_screen.dart';
import '../features/teams/screens/team_list_screen.dart';
import '../features/tournaments/screens/tournament_list_screen.dart';
import '../features/tournaments/screens/tournament_setup_screen.dart';
import '../features/matches/screens/match_live_shell_screen.dart';
import '../features/matches/screens/match_scorecard_screen.dart';
import '../features/matches/screens/normal_match_setup_screen.dart';
import '../features/matches/screens/opening_innings_setup_screen.dart';
import '../features/matches/screens/playing_xi_setup_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/matches/normal/new',
      builder: (context, state) => const NormalMatchSetupScreen(),
    ),
    GoRoute(
      path: '/matches/normal/playing-xi',
      builder: (context, state) => const PlayingXiSetupScreen(),
    ),
    GoRoute(
      path: '/matches/:matchId/opening',
      builder: (context, state) => OpeningInningsSetupScreen(
        matchId: int.parse(state.pathParameters['matchId']!),
      ),
    ),
    GoRoute(
      path: '/matches/:matchId/live',
      builder: (context, state) => MatchLiveShellScreen(
        matchId: int.parse(state.pathParameters['matchId']!),
      ),
    ),
    GoRoute(
      path: '/matches/:matchId/scorecard',
      builder: (context, state) => MatchScorecardScreen(
        matchId: int.parse(state.pathParameters['matchId']!),
      ),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) => const TeamListScreen(),
      routes: [
        GoRoute(
          path: ':teamId',
          builder: (context, state) => TeamDetailScreen(
            teamId: int.parse(state.pathParameters['teamId']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/players',
      builder: (context, state) => const PlayerListScreen(),
      routes: [
        GoRoute(
          path: ':playerId',
          builder: (context, state) => PlayerProfileScreen(
            playerId: int.parse(state.pathParameters['playerId']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/tournaments',
      builder: (context, state) => const TournamentListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const TournamentSetupScreen(),
        ),
      ],
    ),
  ],
);
