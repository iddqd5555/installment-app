import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/installments_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/profile_menu_screen.dart';

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
    ProfileMenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showErrorDialog('กรุณาเปิด Location Service (GPS) เพื่อใช้งานแอป');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showErrorDialog('คุณต้องอนุญาตแชร์ตำแหน่งจึงจะใช้งานแอปได้');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showErrorDialog('คุณปิดไม่ให้เข้าถึงตำแหน่งแบบถาวร กรุณาเปิดที่ Settings');
      return;
    }

    _sendLocationSilently(); // เรียกทันทีหลังได้ permission
  }

  Future<void> _sendLocationSilently() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      print("📍 GPS obtained: ${pos.latitude}, ${pos.longitude}, Mocked: ${pos.isMocked}");
      await ApiService().updateLocationSilently(pos.latitude, pos.longitude, pos.isMocked);
    } catch (e) {
      print("🚨 GPS error: $e");
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('แจ้งเตือน'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
