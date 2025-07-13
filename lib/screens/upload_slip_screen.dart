import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class UploadSlipScreen extends StatefulWidget {
  final dynamic payment;

  const UploadSlipScreen({super.key, required this.payment});

  @override
  State<UploadSlipScreen> createState() => _UploadSlipScreenState();
}

class _UploadSlipScreenState extends State<UploadSlipScreen> {
  File? slipFile;
  bool isUploading = false;
  String? message;

  Future<void> pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => slipFile = File(picked.path));
    }
  }

  Future<void> uploadSlip() async {
    if (slipFile == null) return;
    setState(() {
      isUploading = true;
      message = null;
    });

    // Robust extraction
    final installmentRequestId = widget.payment['installment_request_id'] ?? widget.payment['installmentRequestId'] ?? widget.payment['id'];
    final payForDate = widget.payment['payment_due_date'] ?? widget.payment['paymentDueDate'];
    final amountPaid = double.tryParse('${widget.payment['amount'] ?? widget.payment['amount_paid'] ?? "0"}') ?? 0.0;

    if (installmentRequestId == null || payForDate == null) {
      setState(() {
        isUploading = false;
        message = "ข้อมูลสัญญาหรือวันครบกำหนดหาย กรุณาติดต่อแอดมิน";
      });
      return;
    }

    try {
      final result = await ApiService().uploadSlip(
        installmentRequestId: int.tryParse('$installmentRequestId') ?? 0,
        payForDates: [payForDate.toString()],
        amountPaid: amountPaid,
        slipFile: slipFile!,
      );
      setState(() {
        isUploading = false;
        message = result ? "อัปโหลดสลิปสำเร็จ กรุณารออนุมัติ" : "อัปโหลดล้มเหลว!";
      });
    } catch (e) {
      setState(() {
        isUploading = false;
        message = "เกิดข้อผิดพลาด: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("อัปโหลดสลิปชำระเงิน")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (slipFile == null)
              const Text("กรุณาเลือกรูปสลิป"),
            if (slipFile != null)
              Image.file(slipFile!, height: 240),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isUploading ? null : pickSlip,
              icon: const Icon(Icons.upload),
              label: const Text("เลือก/ถ่ายรูปสลิป"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isUploading || slipFile == null ? null : uploadSlip,
              child: isUploading ? const CircularProgressIndicator() : const Text("ส่งสลิป"),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains("สำเร็จ") ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
