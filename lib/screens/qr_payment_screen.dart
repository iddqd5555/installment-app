import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final amountController = TextEditingController(text: '1.00');
  String? qrImageBase64;
  String? qrRef;
  String status = 'ยังไม่สร้าง QR';
  bool isLoading = false;

  Future<void> _createQr() async {
    setState(() {
      isLoading = true;
      qrImageBase64 = null;
      qrRef = null;
      status = 'กำลังสร้าง QR...';
    });

    final result = await _paymentService.createQrPayment(
      amount: amountController.text.trim(),
      qrType: 3,
    );

    setState(() {
      isLoading = false;
      if (result != null && result['success'] == true) {
        final data = result['data'];
        qrImageBase64 = data['qrCodeImage'];
        qrRef = data['qrRef'];
        status = 'สร้าง QR สำเร็จ';
      } else {
        status = result?['message'] ?? 'สร้าง QR ไม่สำเร็จ';
      }
    });
  }

  Future<void> _checkStatus() async {
    if (qrRef == null) return;
    setState(() => status = 'กำลังตรวจสอบสถานะ...');
    final result = await _paymentService.getQrStatus(qrRef!);
    setState(() {
      if (result != null && result['status'] != null) {
        status = 'สถานะล่าสุด: ${result['status']}';
      } else {
        status = 'ตรวจสอบสถานะไม่สำเร็จ';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน QR')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ยอดชำระ (บาท)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _createQr,
              child: Text(isLoading ? 'กำลังสร้าง QR...' : 'สร้าง QR'),
            ),
            const SizedBox(height: 30),
            if (qrImageBase64 != null)
              Column(
                children: [
                  const Text('QR ที่สร้างได้', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Image.memory(base64Decode(qrImageBase64!)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _checkStatus,
                    child: const Text('เช็คสถานะ'),
                  ),
                ],
              ),
            const SizedBox(height: 30),
            Text(
              status,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
