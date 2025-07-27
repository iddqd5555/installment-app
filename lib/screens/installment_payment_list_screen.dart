import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'installment_dashboard_screen.dart';

class InstallmentPaymentListScreen extends StatefulWidget {
  @override
  State<InstallmentPaymentListScreen> createState() => _InstallmentPaymentListScreenState();
}

class _InstallmentPaymentListScreenState extends State<InstallmentPaymentListScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  List<dynamic> contracts = [];

  @override
  void initState() {
    super.initState();
    fetchContracts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchContracts();
  }

  Future<void> fetchContracts() async {
    setState(() => isLoading = true);
    final data = await apiService.getInstallmentRequests();
    setState(() {
      contracts = data;
      isLoading = false;
    });
  }

  Color _secondary(BuildContext ctx) => Theme.of(ctx).colorScheme.secondary;

  String fnum(dynamic n) {
    final v = double.tryParse(n?.toString() ?? '0') ?? 0.0;
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('เลือกเลขที่สัญญาเพื่อชำระเงิน', style: GoogleFonts.prompt(color: _secondary(context), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _secondary(context)),
            onPressed: fetchContracts,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : contracts.isEmpty
              ? Center(child: Text('ไม่พบข้อมูลสัญญาผ่อน', style: GoogleFonts.prompt(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: fetchContracts,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    itemCount: contracts.length,
                    itemBuilder: (context, index) {
                      final contract = contracts[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.07),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(Icons.assignment_turned_in_rounded, color: _secondary(context), size: 32),
                          title: Text('เลขที่สัญญา: ${contract['contract_number'] ?? '-'}',
                              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: _secondary(context))),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ยอดผ่อนรวม: ${fnum(contract['total_installment_amount'])} บาท',
                                style: GoogleFonts.prompt(
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                ),
                              ),
                              Text('สถานะ: ${contract['status'] ?? "-"}', style: GoogleFonts.prompt(color: Colors.white70)),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white60),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InstallmentDashboardScreen(installmentRequestId: contract['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
