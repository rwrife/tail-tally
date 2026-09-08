import 'package:flutter/material.dart';

/// Root widget for Tail Tally's local-first mobile experience.
class TailTallyApp extends StatelessWidget {
  const TailTallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tail Tally',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff41644a)),
        useMaterial3: true,
      ),
      home: const _WelcomeScreen(),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tail Tally')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Shared pet-care routines, kept on this device.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
