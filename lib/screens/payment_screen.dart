import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เก็บเงิน"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "หน้าชำระเงิน/ประวัติการชำระ (กำลังพัฒนา)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
