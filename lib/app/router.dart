import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/home_screen.dart';
import '../features/management/screens/settings_screen.dart';
import '../features/players/screens/player_list_screen.dart';
import '../features/teams/screens/team_detail_screen.dart';
import '../features/teams/screens/team_list_screen.dart';
import '../features/tournaments/screens/tournament_list_screen.dart';
import '../features/tournaments/screens/tournament_setup_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
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
