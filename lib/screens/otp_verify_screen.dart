import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;
  String? errorMsg;

  void verifyOtp() async {
    setState(() { isLoading = true; errorMsg = null; });
    final otp = otpController.text.trim();

    final resp = await ApiService().verifyOtp(widget.email, otp);

    setState(() => isLoading = false);

    if (resp['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email, otp: otp),
        ),
      );
    } else {
      setState(() { errorMsg = resp['message'] ?? "OTP ไม่ถูกต้อง"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('ยืนยันรหัส OTP', style: GoogleFonts.prompt()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text("กรอกรหัส OTP 6 หลักที่ส่งไปยังอีเมล", style: GoogleFonts.prompt(fontSize: 16)),
              const SizedBox(height: 22),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("ยืนยัน", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 17)),
                  onPressed: isLoading ? null : verifyOtp,
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: GoogleFonts.prompt(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
