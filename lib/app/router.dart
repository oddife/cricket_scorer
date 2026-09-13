import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/home_screen.dart';
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
