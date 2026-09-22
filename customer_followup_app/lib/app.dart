import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

class CustomerFollowupApp extends StatelessWidget {
  const CustomerFollowupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Follow-up',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}
