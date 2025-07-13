import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'upload_slip_screen.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final int installmentRequestId; //เพิ่มตรงนี้

  const PaymentScreen({super.key, required this.installmentRequestId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> payments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  fetchPayments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getInstallmentPayments(widget.installmentRequestId);

      final pendingPayments = data.where((p) =>
        !(p['status'] == 'approved' && p['payment_status'] == 'paid') && 
        double.tryParse('${p['amount']}')! > 0).toList();

      setState(() {
        payments = pendingPayments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
        isLoading = false;
      });
    }
  }

  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      final d = DateTime.parse(dt);
      return DateFormat('d MMM yyyy', 'th').format(d);
    } catch (_) {
      return dt ?? "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: const Text('ข้อมูลผ่อนและชำระเงิน'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
            ? Center(child: Text(errorMessage!, style: const TextStyle(fontSize: 18, color: Colors.red)))
            : payments.isEmpty
              ? const Center(child: Text("งวดทั้งหมดชำระครบแล้ว", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: payments.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, idx) {
                    final p = payments[idx];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: Colors.orange, size: 32),
                        title: Text('ยอดที่ต้องชำระ: ${p['amount']} บาท'),
                        subtitle: Text('วันครบกำหนด: ${formatDate(p['payment_due_date'])}'),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text("อัปโหลดสลิป"),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UploadSlipScreen(payment: p),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
