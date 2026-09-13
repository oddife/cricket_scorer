import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
