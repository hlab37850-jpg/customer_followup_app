import 'package:flutter/material.dart';

void main() {
  runApp(const CustomerFollowupApp());
}

class CustomerFollowupApp extends StatelessWidget {
  const CustomerFollowupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Follow-up',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(child: Text('مرحبا - تطبيق إدارة المتابعات')),
      ),
    );
  }
}
