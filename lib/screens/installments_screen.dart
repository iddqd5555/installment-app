import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchInstallments();
  }

  Future<void> fetchInstallments() async {
    setState(() { isLoading = true; });
    final data = await apiService.getInstallmentRequests();
    setState(() {
      installments = data ?? [];
      isLoading = false;
    });
  }

  Color getStatusColor(BuildContext ctx, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'approved':
        return Theme.of(ctx).colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Theme.of(ctx).colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  String fnum(dynamic n) {
    final v = double.tryParse(n?.toString() ?? '0') ?? 0.0;
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('สัญญาการผ่อนของฉัน', style: GoogleFonts.prompt(color: accent, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accent),
            onPressed: fetchInstallments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (installments.isEmpty
              ? Center(child: Text("ไม่พบข้อมูลสัญญา", style: GoogleFonts.prompt(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: fetchInstallments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: installments.length,
                    itemBuilder: (context, index) {
                      final installment = installments[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.07),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, size: 32, color: getStatusColor(context, installment['status'] ?? 'pending')),
                          title: Text(
                            'สัญญาเลขที่: ${installment['contract_number'] ?? "-"}',
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: accent),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('จำนวนทอง: ${fnum(installment['gold_amount'])} บาท', style: GoogleFonts.prompt(color: Colors.black87)),
                              Text('ยอดรวมที่ต้องผ่อน: ${fnum(installment['total_installment_amount'])} บาท', style: GoogleFonts.prompt(color: Colors.black54)),
                              Text('ผ่อนงวดละ: ${fnum(installment['daily_payment_amount'])} บาท', style: GoogleFonts.prompt(color: Colors.black54)),
                              Text('จำนวนวัน: ${installment['installment_period'] ?? "-"}', style: GoogleFonts.prompt(color: Colors.black38)),
                              Text('สถานะ: ${installment['status']}', style: GoogleFonts.prompt(color: getStatusColor(context, installment['status']))),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black26),
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
                )),
    );
  }
}
