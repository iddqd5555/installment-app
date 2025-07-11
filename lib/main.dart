import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
// import 'screens/qr_payment_screen.dart'; // ถ้าไม่ได้ใช้ที่ main ให้คอมเมนต์ออก

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Installment App',
      home: LoginScreen(), // เริ่มต้นจากหน้า Login
    );
  }
}
