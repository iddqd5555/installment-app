import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'otp_verify_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  String? successMsg;

  void sendOtp() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      successMsg = null;
    });
    final email = emailController.text.trim();

    final resp = await ApiService().sendOtp(email);
    setState(() => isLoading = false);

    if (resp['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(email: email),
        ),
      );
    } else {
      setState(() {
        errorMsg = resp['message'] ?? "เกิดข้อผิดพลาด";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('ลืมรหัสผ่าน', style: GoogleFonts.prompt()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text("กรอกอีเมลที่ลงทะเบียนไว้เพื่อรับรหัส OTP 6 หลัก", style: GoogleFonts.prompt(fontSize: 16)),
              const SizedBox(height: 22),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      : Text("ส่งรหัส OTP", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 17)),
                  onPressed: isLoading ? null : sendOtp,
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
