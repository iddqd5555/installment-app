import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  String? successMsg;

  void resetPassword() async {
    setState(() { isLoading = true; errorMsg = null; successMsg = null; });

    if (passwordController.text.trim() != confirmController.text.trim()) {
      setState(() {
        isLoading = false;
        errorMsg = "รหัสผ่านไม่ตรงกัน";
      });
      return;
    }

    final resp = await ApiService().resetPassword(
      widget.email,
      widget.otp,
      passwordController.text.trim(),
    );
    setState(() => isLoading = false);

    if (resp['success'] == true) {
      setState(() { successMsg = "รีเซ็ตรหัสผ่านสำเร็จ!"; });
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      });
    } else {
      setState(() { errorMsg = resp['message'] ?? "รีเซ็ตรหัสผ่านไม่สำเร็จ"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งรหัสผ่านใหม่', style: GoogleFonts.prompt()),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text("ตั้งรหัสผ่านใหม่", style: GoogleFonts.prompt(fontSize: 16)),
              const SizedBox(height: 22),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
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
                      : Text("รีเซ็ตรหัสผ่าน", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 17)),
                  onPressed: isLoading ? null : resetPassword,
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: GoogleFonts.prompt(color: Colors.red)),
              ],
              if (successMsg != null) ...[
                const SizedBox(height: 10),
                Text(successMsg!, style: GoogleFonts.prompt(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
