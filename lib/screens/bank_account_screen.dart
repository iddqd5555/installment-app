import 'package:flutter/material.dart';

class BankAccountScreen extends StatelessWidget {
  const BankAccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บัญชีธนาคาร')),
      body: const Center(child: Text('หน้าบัญชีธนาคาร')),
    );
  }
}
