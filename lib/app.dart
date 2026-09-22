import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';

class CustomerFollowupApp extends StatelessWidget {
  const CustomerFollowupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'متابعة العملاء',
        locale: const Locale('ar'),
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          fontFamily: 'sans',
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
