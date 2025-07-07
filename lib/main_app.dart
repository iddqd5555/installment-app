// ตัวอย่างที่ใช้ BottomNavigationBar
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'installments_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart'; // ต้อง import อันนี้ (ของใหม่)

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    InstallmentsScreen(),
    PaymentScreen(),
    ProfileScreen(), // ต้องเป็น ProfileScreen() ตัวใหม่
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'สินเชื่อ'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'เก็บเงิน'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red[900],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
      ),
    );
  }
}
