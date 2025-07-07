import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("บัญชีของฉัน", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // Header
          Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.red[100],
                child: const Icon(Icons.account_circle, size: 60, color: Color(0xFFB71C1C)),
              ),
              const SizedBox(height: 8),
              Text(
                "ชื่อ-นามสกุลผู้ใช้", // เปลี่ยนเป็นข้อมูล user จริงในภายหลัง
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "เบอร์โทร 08x-xxxxxxx", // เปลี่ยนเป็นเบอร์จริงในภายหลัง
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const Divider(height: 36),
          _buildMenu(
            icon: Icons.person,
            title: "แก้ไขข้อมูลส่วนตัว",
            onTap: () {},
          ),
          _buildMenu(
            icon: Icons.lock,
            title: "เปลี่ยนรหัสผ่าน",
            onTap: () {},
          ),
          _buildMenu(
            icon: Icons.history,
            title: "ประวัติการผ่อนชำระ",
            onTap: () {},
          ),
          _buildMenu(
            icon: Icons.notifications,
            title: "แจ้งเตือน",
            onTap: () {},
          ),
          _buildMenu(
            icon: Icons.article,
            title: "ข้อตกลง/เงื่อนไขการผ่อนทอง",
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildMenu(
            icon: Icons.exit_to_app,
            title: "ออกจากระบบ",
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("ยืนยันออกจากระบบ?"),
                  content: const Text("คุณต้องการออกจากระบบใช่หรือไม่?"),
                  actions: [
                    TextButton(child: const Text("ยกเลิก"), onPressed: () => Navigator.pop(ctx, false)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.of(context).pushNamedAndRemoveUntil("/login", (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenu({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.red[800]),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor ?? Colors.black)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF9E9E9E)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
    );
  }
}
