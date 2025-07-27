import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class InstallmentDashboardScreen extends StatefulWidget {
  final int installmentRequestId;
  const InstallmentDashboardScreen({super.key, required this.installmentRequestId});

  @override
  State<InstallmentDashboardScreen> createState() => _InstallmentDashboardScreenState();
}

class _InstallmentDashboardScreenState extends State<InstallmentDashboardScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;
  dynamic contract;
  double totalBalance = 0;

  @override
  void initState() {
    super.initState();
    fetchContract();
  }

  Future<void> fetchContract() async {
    setState(() => isLoading = true);
    final data = await apiService.getInstallmentRequests();
    contract = data.firstWhere(
      (c) => c['id'] == widget.installmentRequestId,
      orElse: () => null,
    );
    totalBalance = double.tryParse('${contract?['advance_payment'] ?? '0'}') ?? 0;
    setState(() => isLoading = false);
  }

  Color _danger(BuildContext ctx) => Theme.of(ctx).colorScheme.error;
  Color _primary(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;
  Color _secondary(BuildContext ctx) => Theme.of(ctx).colorScheme.secondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('ข้อมูลสัญญาการผ่อน', style: GoogleFonts.prompt(color: _secondary(context), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('เติมไว้: ${totalBalance.toStringAsFixed(2)} ฿',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber)),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : contract == null
              ? Center(child: Text("ไม่พบข้อมูลสัญญา", style: GoogleFonts.prompt(color: Colors.white70)))
              : buildDetailBody(context),
    );
  }

  Widget buildDetailBody(BuildContext context) {
    final contractNumber = contract['contract_number'] ?? '-';
    final status = contract['status'] ?? '-';

    // *** เหลือทศนิยม 2 ตำแหน่ง ***
    double totalAmount = double.tryParse(contract['total_installment_amount']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เลขที่สัญญา: $contractNumber', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16, color: _secondary(context))),
                  SizedBox(height: 2),
                  Text(
                    'ยอดต้องผ่อนทั้งหมด: ${totalAmount.toStringAsFixed(2)} บาท',
                    style: GoogleFonts.prompt(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                  ),
                  Text('สถานะ: $status', style: GoogleFonts.prompt(color: Colors.white70)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.upload_file, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondary(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 26),
              textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              elevation: 5,
            ),
            label: Text("อัปโหลดสลิป"),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(installmentRequestId: widget.installmentRequestId),
                ),
              );
              if (result == true) {
                fetchContract();
              }
            },
          ),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📌 บัญชีสำหรับชำระเงิน', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: _secondary(context))),
                  Divider(),
                  Text('ธนาคาร: กสิกรไทย', style: GoogleFonts.prompt(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
                  Text('ชื่อบัญชี: บริษัท วิสดอม โกลด์ กรุ้ป จำกัด', style: GoogleFonts.prompt(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)),
                  Text('เลขที่บัญชี: 865-1-00811-6', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
