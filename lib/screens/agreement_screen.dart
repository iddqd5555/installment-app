import 'package:flutter/material.dart';

class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อตกลงผ่อนทอง')),
      body: const Center(child: Text('หน้าข้อตกลงผ่อนทอง')),
    );
  }
}
