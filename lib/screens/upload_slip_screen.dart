import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (picked != null && mounted) {
      setState(() => slipFile = File(picked.path));
    }
  }

  Future<void> uploadSlip() async {
    if (slipFile == null) return;
    setState(() {
      isUploading = true;
      message = null;
    });

    final installmentRequestId = widget.payment['installment_request_id'] ?? widget.payment['installmentRequestId'] ?? widget.payment['id'];
    if (installmentRequestId == null) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        message = "ข้อมูลสัญญาหาย กรุณาติดต่อแอดมิน";
      });
      return;
    }

    try {
      final result = await ApiService().uploadSlip(
        installmentRequestId: int.tryParse('$installmentRequestId') ?? 0,
        slipFile: slipFile!,
      );

      if (!mounted) return;
      setState(() {
        isUploading = false;
        message = result['success'] ? "อัปโหลดสลิปสำเร็จ กรุณารออนุมัติ" : "อัปโหลดล้มเหลว: ${result['message']}";
      });

      if (result['success'] && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        message = "เกิดข้อผิดพลาด: $e";
      });
    }
  }

  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("อัปโหลดสลิปชำระเงิน", style: GoogleFonts.prompt(color: _accent(context), fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (slipFile == null)
              Text("กรุณาเลือกรูปสลิป", style: GoogleFonts.prompt()),
            if (slipFile != null)
              Image.file(slipFile!, height: 240),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isUploading ? null : pickSlip,
              icon: const Icon(Icons.upload),
              label: const Text("เลือก/ถ่ายรูปสลิป"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent(context),
                textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isUploading || slipFile == null ? null : uploadSlip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("ส่งสลิป"),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message!,
                  style: GoogleFonts.prompt(
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
