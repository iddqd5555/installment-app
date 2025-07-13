import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'installment_dashboard_screen.dart';
import 'login_screen.dart';
import 'package:installment_app/screens/payment_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  dynamic dashboardData;
  bool isLoading = true;
  List<dynamic> paymentHistory = [];
  String? errorMessage;
  int _selectedIndex = 0;
  int? installmentRequestId;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  fetchDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await apiService.getDashboardData();
      print("DASHBOARD DATA: $data");
      if (data == null) {
        setState(() {
          errorMessage = "โหลดข้อมูล dashboard ไม่สำเร็จ หรือ Token ผิด";
          isLoading = false;
        });
        return;
      }
      setState(() {
        dashboardData = data;
        paymentHistory = data['payment_history'] ?? [];
        installmentRequestId = data['installment_request_id'] ?? 1;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
        isLoading = false;
      });
    }
  }

  double parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
  }

  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      final d = DateTime.parse(dt);
      return DateFormat('d MMM yyyy HH:mm', 'th').format(d);
    } catch (_) {
      return dt;
    }
  }

  // ==== เพิ่มฟังก์ชันคำนวณค้างชำระ ====
  int countOverdueInstallments({
    required String startDate,
    required int period,
  }) {
    final DateTime start = DateTime.parse(startDate);
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < period; i++) {
      final due = start.add(Duration(days: i));
      if (due.isBefore(now)) {
        count++;
      }
    }
    return count;
  }

  double calculateOverdueTotal({
    required String startDate,
    required int period,
    required double dailyAmount,
  }) {
    final overdue = countOverdueInstallments(startDate: startDate, period: period);
    return overdue * dailyAmount;
  }

  int daysPassedFromStart(String startDate) {
    final start = DateTime.parse(startDate);
    final now = DateTime.now();
    final diff = now.difference(start).inDays;
    return diff >= 0 ? diff : 0;
  }

  Widget buildOverdueRow(int overdueCount, double overdueTotal) {
    if (overdueCount <= 0) {
      return const SizedBox.shrink();
    }
    return detailRow(
      Icons.error,
      'ยอดค้างชำระ ($overdueCount งวด)',
      '${overdueTotal.toStringAsFixed(2)} บาท',
    );
  }

  Color? getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green[700];
      case 'pending':
        return Colors.orange[700];
      case 'rejected':
        return Colors.red[700];
      default:
        return Colors.grey[700];
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_top;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'pending':
        return 'รอตรวจสอบ';
      case 'rejected':
        return 'ไม่อนุมัติ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Future<void> doLogout() async {
    await apiService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Widget _buildMainDashboard() {
    // --- เตรียมข้อมูลใช้คำนวณงวดค้าง/วันค้าง ---
    final String startDate = dashboardData?['start_date'] ?? '2025-07-01';
    final int period = dashboardData?['installment_period'] ?? 45;
    final double dailyAmount = dashboardData?['daily_payment_amount'] ?? 251.0;
    final int overdueCount = countOverdueInstallments(startDate: startDate, period: period);
    final double overdueTotal = calculateOverdueTotal(startDate: startDate, period: period, dailyAmount: dailyAmount);
    final int daysPassed = daysPassedFromStart(startDate);

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : (errorMessage != null)
            ? Center(
                child: Text(errorMessage!, style: const TextStyle(fontSize: 18, color: Colors.red)),
              )
            : (dashboardData == null || dashboardData.isEmpty)
                ? const Center(
                    child: Text("ไม่มีข้อมูลการผ่อน", style: TextStyle(fontSize: 18)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📌 ผ่อนทองจำนวน: ${dashboardData?['gold_amount'] ?? '-'} บาททอง',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const Divider(height: 20, thickness: 1),
                                detailRow(Icons.payment, 'ยอดที่ต้องชำระวันนี้', '${parseNumber(dashboardData?['due_today']).toStringAsFixed(2)} บาท'),
                                detailRow(Icons.account_balance_wallet, 'ยอดชำระล่วงหน้า', '${parseNumber(dashboardData?['advance_payment']).toStringAsFixed(2)} บาท'),
                                detailRow(Icons.calendar_today, 'วันชำระครั้งถัดไป', dashboardData?['next_payment_date'] ?? '-'),
                                detailRow(Icons.warning, 'ค่าปรับสะสม', '${parseNumber(dashboardData?['total_penalty']).toStringAsFixed(2)} บาท'),
                                buildOverdueRow(overdueCount, overdueTotal), // <<< เพิ่มนี้!
                                const Divider(height: 20, thickness: 1),
                                const Text('💰 ชำระแล้วทั้งหมด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: parseNumber(dashboardData?['total_installment_amount']) != 0
                                      ? parseNumber(dashboardData?['total_paid']) / parseNumber(dashboardData?['total_installment_amount'])
                                      : 0,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.green,
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${parseNumber(dashboardData?['total_paid']).toStringAsFixed(2)} / ${parseNumber(dashboardData?['total_installment_amount']).toStringAsFixed(2)} บาท (${((parseNumber(dashboardData?['total_paid']) / (parseNumber(dashboardData?['total_installment_amount']) == 0 ? 1 : parseNumber(dashboardData?['total_installment_amount'])) ) * 100).toStringAsFixed(2)}%)',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const Divider(height: 20, thickness: 1),
                                Text(
                                  '⏳ ระยะเวลาการผ่อน: $daysPassed / $period วัน',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: period != 0 ? daysPassed / period : 0,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('${((daysPassed / (period == 0 ? 1 : period)) * 100).toStringAsFixed(2)}%', style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📋 ประวัติการชำระเงินล่าสุด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                const Divider(height: 18),
                                if (paymentHistory.isEmpty)
                                  const Text("ยังไม่มีประวัติการชำระ", style: TextStyle(color: Colors.grey)),
                                ...paymentHistory.map((p) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,1))]
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(getStatusIcon(p['status']), color: getStatusColor(p['status']), size: 30),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${parseNumber(p['amount_paid']?.toString()).toStringAsFixed(2)} บาท",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text(formatDate(p['payment_due_date']), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(getStatusIcon(p['status']), color: getStatusColor(p['status'])),
                                          const SizedBox(width: 4),
                                          Text(
                                            getStatusText(p['status']),
                                            style: TextStyle(
                                              color: getStatusColor(p['status']),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildMainDashboard();
    }
    if (_selectedIndex == 1) {
      if (installmentRequestId == null) {
        return const Center(child: Text("ไม่พบข้อมูลสัญญา"));
      }
      // 👇 ส่ง installmentRequestId ไป PaymentScreen
      return PaymentScreen(installmentRequestId: installmentRequestId!);
    }
    if (_selectedIndex == 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ออกจากระบบ", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: doLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout / ออกจากระบบ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: const Text('📊 Dashboard การผ่อนของคุณ', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey[700],
        onTap: (index) {
          setState(() { _selectedIndex = index; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'ชำระเงิน'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'ออกจากระบบ'),
        ],
      ),
    );
  }

  Widget detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
