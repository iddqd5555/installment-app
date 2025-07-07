import 'package:flutter/material.dart';
import 'upload_document_screen.dart';
import 'package:intl/intl.dart';

class InstallmentDetailScreen extends StatelessWidget {
  final dynamic installment;

  InstallmentDetailScreen({required this.installment});

  String formatDate(String? dt) {
    if (dt == null) return "-";
    try {
      final d = DateTime.parse(dt);
      return DateFormat('d MMM yyyy HH:mm', 'th').format(d);
    } catch (_) {
      return dt ?? "-";
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
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
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสัญญาสินเชื่อ'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
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
          Divider(),
          Text('ประวัติการชำระเงิน:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...(installment['payments'] as List<dynamic>? ?? []).map((payment) {
            return Card(
              child: ListTile(
                leading: Icon(Icons.payment, color: getStatusColor(payment['status'])),
                title: Text(
                  'เลขที่การชำระ: ${payment['payment_number'] ?? "-"}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('วันที่: ${formatDate(payment['payment_due_date'])}'),
                    Text('ยอดที่ต้องชำระ: ${payment['amount']} บาท'),
                    Text('ยอดที่ชำระแล้ว: ${payment['amount_paid']} บาท'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      payment['status'] == 'approved'
                        ? Icons.check_circle
                        : payment['status'] == 'pending'
                          ? Icons.hourglass_top
                          : Icons.cancel,
                      color: getStatusColor(payment['status']),
                      size: 26,
                    ),
                    SizedBox(height: 4),
                    Text(getStatusText(payment['status']),
                        style: TextStyle(
                          color: getStatusColor(payment['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                        )),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.upload_file),
            label: Text('อัปโหลดเอกสารเพิ่มเติม'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => UploadDocumentScreen(installmentId: installment['id']),
              ));
            },
          ),
        ],
      ),
    );
  }
}
