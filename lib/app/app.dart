import 'package:flutter/material.dart';

import 'router.dart';

class CricketScorerApp extends StatelessWidget {
  const CricketScorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cricket Scorer',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}