import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main_app.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  void login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    bool success = await ApiService().login(
      phoneController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainApp()),
      );
    } else {
      setState(() {
        errorMessage = "เข้าสู่ระบบไม่สำเร็จ!";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;
  bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final labelColor = _isDark(context) ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: _accent(context),
                child: Text(
                  "W",
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "WisdomGold",
                style: GoogleFonts.prompt(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _accent(context),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "ระบบผ่อนทอง by WisdomGold",
                style: GoogleFonts.prompt(
                  color: _isDark(context) ? Colors.white70 : Colors.black45,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 34),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'เบอร์โทรศัพท์',
                  style: GoogleFonts.prompt(color: labelColor, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              _modernInput(
                context: context,
                controller: phoneController,
                icon: Icons.phone_android,
                hint: 'ระบุเบอร์โทรศัพท์',
                isPassword: false,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'รหัสผ่าน',
                  style: GoogleFonts.prompt(color: labelColor, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              _modernInput(
                context: context,
                controller: passwordController,
                icon: Icons.lock_rounded,
                hint: '********',
                isPassword: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isLoading
                      ? SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.login, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                  ),
                  label: Text(isLoading ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ"),
                  onPressed: isLoading ? null : login,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 18),
                Text(errorMessage!, style: GoogleFonts.prompt(color: Colors.red)),
              ],
              const SizedBox(height: 12),
                TextButton(
                child: Text("ลืมรหัสผ่าน?", style: GoogleFonts.prompt(color: _accent(context), fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernInput({
    required BuildContext context,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isPassword,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent(context).withOpacity(0.07),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.phone,
        style: GoogleFonts.prompt(color: isDark ? Colors.white : Colors.black87, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _accent(context), size: 24),
          hintText: hint,
          hintStyle: GoogleFonts.prompt(color: isDark ? Colors.white38 : Colors.black26),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }
}
