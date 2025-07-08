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
    _sendLocationIfSafe();
  }

  Future<void> _sendLocationIfSafe() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      // 1. Block emulator/mock location
      if (pos.isMocked) {
        _showErrorDialog('ไม่สามารถใช้งานได้: ตรวจพบการจำลองตำแหน่ง (Mock Location)\nกรุณาใช้กับมือถือจริงเท่านั้น');
        return;
      }
      // 2. Block พิกัดที่อยู่นอกประเทศไทย (lat/lng ไม่อยู่ในขอบเขตไทย)
      if (!_isInThailand(pos.latitude, pos.longitude)) {
        _showErrorDialog('พิกัดของคุณอยู่นอกประเทศไทย กรุณาปิด VPN หรือจำลองตำแหน่ง แล้วลองใหม่');
        return;
      }
      // 3. อัปเดตพิกัดขึ้น backend
      await ApiService().updateLocationSilently(pos.latitude, pos.longitude);
    } catch (e) {
      print("GPS error: $e");
    }
  }

  bool _isInThailand(double lat, double lng) {
    // ประมาณขอบเขตประเทศไทย
    return (lat >= 5.0 && lat <= 21.0) && (lng >= 97.0 && lng <= 106.0);
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
        _ensureLocationPermission();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showErrorDialog('คุณปิดไม่ให้เข้าถึงตำแหน่งแบบถาวร กรุณาเปิดที่ Settings');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (position.isMocked) {
        await _showErrorDialog('พบการจำลองตำแหน่ง (Mock Location)\nหากใช้ VPN หรือ App จำลอง กรุณาปิดก่อน');
      }
    } catch (e) {}
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
