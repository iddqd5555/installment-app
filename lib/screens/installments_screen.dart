import 'package:flutter/material.dart';
import 'package:installment_app/services/api_service.dart';
import 'installment_detail_screen.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> installments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInstallments();
  }

  fetchInstallments() async {
    final data = await apiService.getInstallments();
    setState(() {
      installments = data;
      isLoading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สัญญาสินเชื่อของฉัน'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: installments.length,
              itemBuilder: (context, index) {
                final installment = installments[index];
                return Card(
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(Icons.receipt_long, size: 32, color: getStatusColor(installment['status'])),
                    title: Text(
                      'สัญญาเลขที่: ${installment['contract_number'] ?? "-"}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('เลขที่ชำระเงิน: ${installment['payment_number'] ?? "-"}'),
                        Text('จำนวนทอง: ${installment['gold_amount'] ?? "-"} บาท'),
                        Text('ยอดรวมที่ต้องผ่อน: ${installment['total_installment_amount'] ?? "-"} บาท'),
                        Text('ผ่อนงวดละ: ${installment['daily_payment_amount'] ?? "-"} บาท'),
                        Text('จำนวนวัน: ${installment['installment_period'] ?? "-"}'),
                        Text('สถานะสัญญา: ${installment['status']}'),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InstallmentDetailScreen(installment: installment),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
