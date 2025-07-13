import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'upload_document_screen.dart';
import 'package:intl/intl.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final dynamic installment;

  const InstallmentDetailScreen({required this.installment, super.key});

  @override
  State<InstallmentDetailScreen> createState() => _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    setState(() => isLoading = true);
    final data = await apiService.getInstallmentPayments(widget.installment['id']);
    // กรองเฉพาะ amount > 0 เท่านั้น
    setState(() {
      payments = data.where((p) => double.tryParse('${p['amount'] ?? 0}')! > 0).toList();
      isLoading = false;
    });
  }

  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      final d = DateTime.parse(dt);
      return DateFormat('d MMM yyyy', 'th').format(d);
    } catch (_) {
      return dt;
    }
  }

  Color getStatusColor(Map payment) {
    if (payment['status'] == 'approved' && payment['payment_status'] == 'paid') {
      return Colors.green;
    } else if (payment['status'] == 'pending') {
      return Colors.orange;
    } else if (payment['status'] == 'rejected') {
      return Colors.red;
    }
    return Colors.grey;
  }

  String getStatusText(Map payment) {
    if (payment['status'] == 'approved' && payment['payment_status'] == 'paid') {
      return 'จ่ายสำเร็จ (Auto)';
    } else if (payment['status'] == 'pending') {
      return 'รอตรวจสอบ';
    } else if (payment['status'] == 'rejected') {
      return 'ไม่อนุมัติ';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final installment = widget.installment;

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสัญญาสินเชื่อ'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text('เลขที่สัญญา: ${installment['contract_number'] ?? "-"}'),
                    subtitle: Text('เลขที่ชำระเงิน: ${installment['payment_number'] ?? "-"}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text('จำนวนทอง: ${installment['gold_amount'] ?? "-"} บาท'),
                    subtitle: Text('ผ่อนงวดละ: ${installment['daily_payment_amount'] ?? "-"} บาท'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text('ยอดรวมที่ต้องผ่อน: ${installment['total_installment_amount'] ?? "-"} บาท'),
                    subtitle: Text('จำนวนวันในการผ่อน: ${installment['installment_period'] ?? "-"} วัน'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text('วันที่เริ่มสัญญา: ${installment['start_date'] ?? "-"}'),
                    subtitle: Text('สถานะสัญญา: ${installment['status'] ?? "-"}'),
                  ),
                ),
                const Divider(),
                const Text('ประวัติการชำระเงิน (ตามงวดจริง):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...payments.map((payment) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.payment, color: getStatusColor(payment)),
                      title: Text(
                        'วันที่: ${formatDate(payment['payment_due_date'])}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ยอดที่ต้องชำระ: ${payment['amount']} บาท'),
                          Text('ยอดที่ชำระแล้ว: ${payment['amount_paid']} บาท'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            payment['status'] == 'approved' && payment['payment_status'] == 'paid'
                                ? Icons.check_circle
                                : payment['status'] == 'pending'
                                    ? Icons.hourglass_top
                                    : Icons.cancel,
                            color: getStatusColor(payment),
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getStatusText(payment),
                            style: TextStyle(
                              color: getStatusColor(payment),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('อัปโหลดเอกสารเพิ่มเติม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadDocumentScreen(installmentId: installment['id']),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
