import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  List<dynamic> advancePayments = [];
  List<dynamic> installmentPayments = [];
  String? error;
  final int installmentRequestId = 1; // <- ต้องเปลี่ยนให้ตรงจริง

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await apiService.getPaymentHistory(installmentRequestId);

      // ดึงทั้งหมด ไม่ filter
      advancePayments = (data['advance_payments'] ?? []);
      installmentPayments = (data['installment_payments'] ?? []);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildListTile(Map<String, dynamic> payment, {required bool isAdvance}) {
    final status = payment['payment_status'] ?? '';
    final isPaid = status == 'paid' || status == 'advance';
    final amount = payment['amount']?.toString() ?? '-';
    final date = isAdvance
        ? (payment['created_at']?.toString() ?? '-')
        : (payment['payment_due_date']?.toString() ?? '-');
    final typeText = isAdvance ? 'เติมเงิน' : 'ผ่อนงวด';
    final icon = isAdvance
        ? Icons.account_balance_wallet
        : (isPaid ? Icons.check_circle : Icons.schedule);

    // สีเรียบๆ แบบ Mobile banking
    final iconColor = isAdvance
        ? Colors.blue[700]
        : (isPaid ? Colors.green[600] : Colors.orange[700]);

    final mainText = isAdvance
        ? 'เติมเงิน ${amount} บาท'
        : 'ผ่อนงวด ${amount} บาท';

    final subText = isAdvance
        ? 'วันที่ทำรายการ: ${date.substring(0, 10)}'
        : 'ครบกำหนด: ${date.substring(0, 10)}';

    final trailingText = isAdvance
        ? 'เติมเงิน'
        : (isPaid ? 'ชำระแล้ว' : 'ค้างจ่าย');

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[100],
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(mainText,
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[900],
              )),
          subtitle: Text(subText,
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: Colors.grey[600],
              )),
          trailing: Text(
            trailingText,
            style: GoogleFonts.prompt(
              color: isPaid ? Colors.green[700] : Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          minLeadingWidth: 0,
        ),
        const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          thickness: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการชำระเงิน',
            style: GoogleFonts.prompt(color: accent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: accent),
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                  'ผิดพลาด: $error',
                  style: GoogleFonts.prompt(color: Theme.of(context).colorScheme.error),
                ))
              : (advancePayments.isEmpty && installmentPayments.isEmpty)
                  ? Center(
                      child: Text('ไม่มีประวัติ',
                          style: GoogleFonts.prompt(color: Colors.black45, fontSize: 16)))
                  : ListView(
                      children: [
                        const SizedBox(height: 10),
                        if (advancePayments.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 22, top: 4, bottom: 2),
                            child: Text('ธุรกรรมเติมเงิน',
                                style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                    fontSize: 15)),
                          ),
                          ...advancePayments.map((p) =>
                              _buildListTile(p as Map<String, dynamic>, isAdvance: true)),
                        ],
                        if (installmentPayments.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 22, top: 14, bottom: 2),
                            child: Text('ธุรกรรมผ่อนงวด',
                                style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontSize: 15)),
                          ),
                          ...installmentPayments.map((p) =>
                              _buildListTile(p as Map<String, dynamic>, isAdvance: false)),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
    );
  }
}
