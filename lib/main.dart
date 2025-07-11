import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Installment App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: FutureBuilder<String>(
        future: ApiService().getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final token = snapshot.data ?? '';
          return token.isEmpty ? const LoginScreen() : const DashboardScreen();
        },
      ),
    );
  }
}
