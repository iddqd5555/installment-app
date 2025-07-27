import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/installments_screen.dart';
import 'screens/installment_payment_list_screen.dart'; // <-- ใช้ไฟล์นี้
import 'screens/notifications_screen.dart';
import 'screens/profile_menu_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  int notificationCount = 0;
  static late List<Widget> _widgetOptions;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _ensureLocationPermission();
    _widgetOptions = [
      DashboardScreen(),
      InstallmentsScreen(),
      InstallmentPaymentListScreen(), // <-- ใช้ตัวนี้เป็นเมนู “เก็บเงิน”
      NotificationsScreen(onNotificationCount: (count) {
        if (notificationCount != count) {
          setState(() => notificationCount = count);
        }
      }),
      ProfileMenuScreen(),
    ];
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
    _sendLocationSilently();
  }

  Future<void> _sendLocationSilently() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await apiService.updateLocationSilently(pos.latitude, pos.longitude, pos.isMocked);
    } catch (_) {}
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

  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'สินเชื่อ'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'เก็บเงิน'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                if (notificationCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text('$notificationCount',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
            label: 'แจ้งเตือน',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: _accent(context),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
