import 'package:flutter/material.dart';
import '../main_app.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    setState(() => isLoading = true);

    bool success = await ApiService().login(
      phoneController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainApp()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เข้าสู่ระบบไม่สำเร็จ!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.amber[700],
                child: Text("W", style: TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 16),
              Text(
                "WisdomGold",
                style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold,
                  color: Colors.red[900], letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text("ระบบผ่อนทอง by WisdomGold", style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 28),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_android),
                  labelText: 'เบอร์โทรศัพท์',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isLoading ? SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ) : Icon(Icons.login, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  label: Text(isLoading ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ"),
                  onPressed: isLoading ? null : login,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                child: Text("ลืมรหัสผ่าน?", style: TextStyle(color: Colors.red[900])),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
