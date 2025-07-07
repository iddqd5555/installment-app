import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  fetchDashboard() async {
    final data = await apiService.getDashboardData();
    final payments = await apiService.getPaymentHistory();
    setState(() {
      dashboardData = data;
      paymentHistory = payments;
      isLoading = false;
    });
  }

  double parseNumber(String? value) {
    return double.tryParse(value?.replaceAll(',', '') ?? '0') ?? 0;
  }

  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      final d = DateTime.parse(dt);
      return DateFormat('d MMM yyyy HH:mm', 'th').format(d);
    } catch (_) {
      return dt ?? "-";
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: Text('📊 Dashboard การผ่อนของคุณ', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (dashboardData == null || dashboardData.isEmpty)
              ? Center(
                  child: Text(
                    "ไม่มีข้อมูลการผ่อน",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
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
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(height: 20, thickness: 1),
                              detailRow(Icons.payment, 'ยอดที่ต้องชำระวันนี้', '${parseNumber(dashboardData?['due_today']).toStringAsFixed(2)} บาท'),
                              detailRow(Icons.account_balance_wallet, 'ยอดชำระล่วงหน้า', '${parseNumber(dashboardData?['advance_payment']).toStringAsFixed(2)} บาท'),
                              detailRow(Icons.calendar_today, 'วันชำระครั้งถัดไป', dashboardData?['next_payment_date'] ?? '-'),
                              detailRow(Icons.warning, 'ค่าปรับสะสม', '${parseNumber(dashboardData?['total_penalty']).toStringAsFixed(2)} บาท'),
                              Divider(height: 20, thickness: 1),
                              Text('💰 ชำระแล้วทั้งหมด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: parseNumber(dashboardData?['total_installment_amount']) != 0
                                    ? parseNumber(dashboardData?['total_paid']) / parseNumber(dashboardData?['total_installment_amount'])
                                    : 0,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${parseNumber(dashboardData?['total_paid']).toStringAsFixed(2)} / ${parseNumber(dashboardData?['total_installment_amount']).toStringAsFixed(2)} บาท (${((parseNumber(dashboardData?['total_paid']) / parseNumber(dashboardData?['total_installment_amount'])) * 100).toStringAsFixed(2)}%)',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Divider(height: 20, thickness: 1),
                              Builder(
                                builder: (_) {
                                  int installmentPeriod = (dashboardData?['installment_period'] as num?)?.toInt() ?? 1;
                                  int daysPassed = ((dashboardData?['days_passed'] as num?)?.toInt() ?? 0)
                                      .clamp(0, installmentPeriod)
                                      .toInt();
                                  double timeProgress = installmentPeriod != 0 ? daysPassed / installmentPeriod : 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⏳ ระยะเวลาการผ่อน: $daysPassed / $installmentPeriod วัน',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: timeProgress,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.blue,
                                        minHeight: 12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('${(timeProgress * 100).toStringAsFixed(2)}%', style: TextStyle(fontSize: 14)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📋 ประวัติการชำระเงินล่าสุด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Divider(height: 18),
                              if (paymentHistory.isEmpty)
                                Text("ยังไม่มีประวัติการชำระ", style: TextStyle(color: Colors.grey)),
                              ...paymentHistory.map((p) => Container(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,1))]
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle, color: Colors.green, size: 30),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("โอนเงิน", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text(formatDate(p['payment_due_date']), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${parseNumber(p['amount_paid']?.toString()).toStringAsFixed(2)} บาท',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Row(
                                      children: [
                                        Icon(getStatusIcon(p['status']), color: getStatusColor(p['status'])),
                                        SizedBox(width: 4),
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
                ),
    );
  }

  Widget detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, color: Colors.black87))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
