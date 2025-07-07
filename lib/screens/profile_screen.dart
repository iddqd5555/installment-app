import 'package:flutter/material.dart';
// import หน้าอื่นๆตามต้องการ
// import 'edit_profile_screen.dart';
// import 'change_password_screen.dart';
// import 'loan_history_screen.dart';
// import 'terms_screen.dart';
// import 'notifications_screen.dart';

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
                child: Icon(Icons.account_circle, size: 60, color: Colors.red[900]),
              ),
              const SizedBox(height: 8),
              Text(
                "ชื่อ-นามสกุลผู้ใช้", // ใส่ชื่อจากข้อมูล user
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "เบอร์โทร 08x-xxxxxxx", // ใส่เบอร์ user
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const Divider(height: 36),

          // Profile Menu
          _buildMenu(
            icon: Icons.person,
            title: "แก้ไขข้อมูลส่วนตัว",
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
            },
          ),
          _buildMenu(
            icon: Icons.lock,
            title: "เปลี่ยนรหัสผ่าน",
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen()));
            },
          ),
          _buildMenu(
            icon: Icons.history,
            title: "ประวัติการผ่อนชำระ",
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => LoanHistoryScreen()));
            },
          ),
          _buildMenu(
            icon: Icons.notifications,
            title: "แจ้งเตือน",
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen()));
            },
          ),
          _buildMenu(
            icon: Icons.article,
            title: "ข้อตกลง/เงื่อนไขการผ่อนทอง",
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => TermsScreen()));
            },
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
                  title: Text("ยืนยันออกจากระบบ?"),
                  content: Text("คุณต้องการออกจากระบบใช่หรือไม่?"),
                  actions: [
                    TextButton(child: Text("ยกเลิก"), onPressed: () => Navigator.pop(ctx, false)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text("ออกจากระบบ", style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // ทำ logout
                // await ApiService().logout();
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
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
    );
  }
}
