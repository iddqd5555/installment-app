import 'package:flutter/material.dart';
import 'profile_detail_screen.dart';
import 'bank_account_screen.dart';
import 'agreement_screen.dart';
import 'profile_screen.dart';


class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("โปรไฟล์ของฉัน")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("ข้อมูลส่วนตัว"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
        ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text("บัญชีธนาคาร"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankAccountScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("ข้อตกลงผ่อนทอง"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgreementScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("ออกจากระบบ", style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: ทำ logout ที่นี่
            },
          ),
        ],
      ),
    );
  }
}
