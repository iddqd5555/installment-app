import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';

class InstallmentDetailScreen extends StatelessWidget {
  final dynamic installment;

  const InstallmentDetailScreen({super.key, required this.installment});

  Color _danger(BuildContext ctx) => Theme.of(ctx).colorScheme.error;
  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  String formatDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-') return '-';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      if (dateStr.contains('T')) {
        return dateStr.split('T').first;
      }
      return dateStr;
    }
  }

  bool isOverdue(String dateStr) {
    try {
      final due = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      return !due.isAfter(DateTime(now.year, now.month, now.day));
    } catch (e) {
      return false;
    }
  }

  String fnum(dynamic n) {
    final v = double.tryParse(n?.toString() ?? '0') ?? 0.0;
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final payments = (installment['installment_payments'] ?? []) as List<dynamic>;
    final contractNumber = installment['contract_number'] ?? "-";
    final goldAmount = fnum(installment['gold_amount']);
    final period = installment['installment_period']?.toString() ?? "-";
    final totalInstallment = fnum(installment['total_installment_amount']);
    final status = installment['status'] ?? "-";
    final paid = double.tryParse(installment['total_paid']?.toString() ?? '0') ?? 0.0;
    final paidStr = paid.toStringAsFixed(2);
    final installmentId = installment['id'];

    final unpaid = payments
        .where((p) =>
            (p['payment_status'] ?? p['status']) != 'paid' &&
            (p['payment_status'] ?? p['status']) != 'advance' &&
            isOverdue(p['payment_due_date'] ?? ''))
        .toList();

    final paidList = payments
        .where((p) =>
            (p['payment_status'] ?? p['status']) == 'paid' ||
            (p['payment_status'] ?? p['status']) == 'advance')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสัญญา $contractNumber',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: _accent(context))),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).cardColor,
            elevation: 3,
            margin: EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เลขที่สัญญา: $contractNumber',
                      style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16, color: _accent(context))),
                  Text('จำนวนทอง: $goldAmount บาท', style: GoogleFonts.prompt()),
                  Text('จำนวนวันผ่อน: $period วัน', style: GoogleFonts.prompt()),
                  Text('ยอดรวมที่ต้องผ่อน: $totalInstallment บาท', style: GoogleFonts.prompt()),
                  Text('สถานะสัญญา: $status', style: GoogleFonts.prompt()),
                  SizedBox(height: 6),
                  Text('ยอดชำระแล้ว: $paidStr บาท',
                      style: GoogleFonts.prompt(color: Colors.green)),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text('อัปโหลดสลิป/ชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (installmentId != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(installmentRequestId: installmentId),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          Text('⏳ งวดค้างชำระ',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.orange[700])),
          if (unpaid.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('ไม่มีงวดค้างชำระ', style: GoogleFonts.prompt(color: Colors.black54)),
            ),
          ...unpaid.map((p) {
            final dueDate = formatDate(p['payment_due_date'] ?? '-');
            final amount = fnum(p['amount']);
            return ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text("ครบกำหนด: $dueDate", style: GoogleFonts.prompt()),
              subtitle: Text("ยอด: $amount บาท", style: GoogleFonts.prompt()),
              trailing: Text('ยังไม่จ่าย', style: GoogleFonts.prompt(color: _danger(context))),
            );
          }).toList(),
          Divider(height: 24, thickness: 1),
          Text('✅ ประวัติชำระงวด',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.green[600])),
          if (paidList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('ไม่มีประวัติชำระ', style: GoogleFonts.prompt(color: Colors.black54)),
            ),
          ...paidList.map((p) {
            final dueDate = formatDate(p['payment_due_date'] ?? '-');
            final amount = fnum(p['amount']);
            final ref = p['ref'] ?? p['payment_number'] ?? p['slip_reference'] ?? '';
            return ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("งวด $dueDate", style: GoogleFonts.prompt()),
              subtitle: Text("ยอด $amount บาท | อ้างอิง: $ref", style: GoogleFonts.prompt()),
            );
          }).toList(),
        ],
      ),
    );
  }
}
