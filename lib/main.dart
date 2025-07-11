import 'package:flutter/material.dart';
import 'screens/installment_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Installment App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InstallmentDashboardScreen(installmentRequestId: 1), // ปรับ id ตาม user จริง
    );
  }
}
