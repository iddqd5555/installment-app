import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final ApiService apiService = ApiService();

  bool isLoading = true;
  List<dynamic> contracts = [];
  dynamic selectedContract;
  List<Map<String, dynamic>> installmentPayments = [];
  List<Map<String, dynamic>> advancePayments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchInstallmentContracts();
    fetchAllAdvancePayments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> fetchInstallmentContracts() async {
    setState(() => isLoading = true);
    try {
      final data = await apiService.getDashboardData();
      if (data == null || data['contracts'] == null || data['contracts'].isEmpty) {
        setState(() {
          contracts = [];
          selectedContract = null;
          isLoading = false;
        });
        return;
      }
      setState(() {
        contracts = data['contracts'] as List<dynamic>;
        selectedContract = contracts.first;
        isLoading = false;
      });
      fetchHistoryForSelected();
    } catch (e) {
      setState(() => isLoading = false);
      print("เกิดข้อผิดพลาดตอนดึงข้อมูล dashboard: $e");
    }
  }

  Future<void> fetchAllAdvancePayments() async {
    try {
      advancePayments = await apiService.getAllAdvancePayments();
      setState(() {});
    } catch (_) {
      advancePayments = [];
      setState(() {});
    }
  }

  Future<void> fetchHistoryForSelected() async {
    setState(() {
      installmentPayments = [];
    });

    if (selectedContract != null && selectedContract['installment_payments'] != null) {
      installmentPayments = List<Map<String, dynamic>>.from(selectedContract['installment_payments']);
    }
    setState(() {});
  }

  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  String formatDate(dynamic value) {
    if (value == null) return "-";
    try {
      DateTime dt;
      if (value is DateTime) {
        dt = value;
      } else if (value is String && value.isNotEmpty && !value.startsWith("0000")) {
        dt = DateTime.parse(value);
      } else {
        return "-";
      }
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return "-";
    }
  }

  bool isSundayToday() {
    return DateTime.now().weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Dashboard การผ่อนของคุณ',
          style: GoogleFonts.prompt(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black87,
              fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _accent(context)),
            tooltip: 'Reload',
            onPressed: () {
              fetchInstallmentContracts();
              fetchAllAdvancePayments();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contracts.isEmpty
              ? Center(child: Text("ไม่พบข้อมูลการผ่อนชำระ", style: GoogleFonts.prompt()))
              : RefreshIndicator(
                  onRefresh: () async {
                    await fetchInstallmentContracts();
                    await fetchAllAdvancePayments();
                  },
                  child: buildBodyByTab(),
                ),
    );
  }

  Future<void> _payInstallmentWithAdvance() async {
    if (selectedContract == null) return;
    final contractId = selectedContract['id'];
    final ok = await apiService.payInstallmentWithAdvance(contractId);
    if (ok == true) {
      await fetchInstallmentContracts();
      await fetchAllAdvancePayments();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ชำระงวดค้างด้วย Advance สำเร็จ')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ชำระเงินไม่สำเร็จ')));
    }
  }

  Widget buildBodyByTab() {
    final sc = selectedContract;
    if (sc == null) return Center(child: Text('ไม่พบข้อมูล', style: GoogleFonts.prompt()));

    double totalAmount = double.tryParse(sc['total_installment_amount']?.toString() ?? '0') ?? 0.0;
    double advancePayment = double.tryParse(sc['advance_payment']?.toString() ?? '0') ?? 0.0;

    List<Map<String, dynamic>> payments = [];
    if (sc['installment_payments'] != null) {
      payments = List<Map<String, dynamic>>.from(sc['installment_payments']);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double usedForPaid = payments
        .where((p) => (p['status'] ?? '') == 'paid')
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['amount_paid']?.toString() ?? '0') ?? 0.0));

    // ยอดครบกำหนด "วันนี้"
    double dueTodayAmount = payments
        .where((p) {
          if ((p['status'] ?? '') != 'pending') return false;
          final due = DateTime.tryParse(p['payment_due_date'] ?? '');
          return due != null &&
              due.year == today.year &&
              due.month == today.month &&
              due.day == today.day;
        })
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0));

    // ยอดค้าง (งวดเก่า)
    double overdueAmount = payments
        .where((p) {
          if ((p['status'] ?? '') != 'pending') return false;
          final due = DateTime.tryParse(p['payment_due_date'] ?? '');
          return due != null && due.isBefore(today);
        })
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0));

    double totalDue = overdueAmount + dueTodayAmount;

    double percentPaid = totalAmount > 0 ? (usedForPaid / totalAmount) * 100 : 0;

    // ✅ นับ "ระยะเวลาผ่อน" จากงวดที่ครบกำหนดแล้ว ไม่ใช่จ่ายแล้ว
    int passedInstallments = payments.where((p) {
      final due = DateTime.tryParse(p['payment_due_date'] ?? '');
      return due != null && !due.isAfter(today);
    }).length;
    int period = (sc['installment_period'] as num?)?.toInt() ?? 0;

    final historyList = payments.where((p) {
      final due = DateTime.tryParse(p['payment_due_date'] ?? '');
      return due != null && !due.isAfter(now);
    }).toList();
    historyList.sort((a, b) {
      final aDate = DateTime.tryParse('${a['payment_due_date'] ?? ''}') ?? DateTime(2000);
      final bDate = DateTime.tryParse('${b['payment_due_date'] ?? ''}') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    List<Map<String, dynamic>> filteredAdvances = advancePayments.where((tx) {
      final contractId = tx['contract_id']?.toString() ?? '';
      final installmentContractId = tx['installment_contract_id']?.toString() ?? '';
      final contractNumber = tx['contract_number']?.toString() ?? '';
      final scId = sc['id']?.toString() ?? '';
      final scContractNumber = sc['contract_number']?.toString() ?? '';
      return (contractId == scId) ||
          (installmentContractId == scId) ||
          (contractNumber == scContractNumber);
    }).toList();

    // *** ปุ่มชำระด้วย Advance ***
    final showAdvancePayButton = advancePayment > 0 &&
      payments.any((p) =>
        (p['status'] ?? '') == 'pending' &&
        (() {
          final due = DateTime.tryParse(p['payment_due_date'] ?? '');
          return due != null && !due.isAfter(today);
        })()
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contracts.length > 1)
            Container(
              margin: EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _accent(context).withOpacity(.12), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<dynamic>(
                  value: selectedContract,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  style: GoogleFonts.prompt(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, fontWeight: FontWeight.w500),
                  icon: Icon(Icons.arrow_drop_down, color: _accent(context)),
                  items: contracts
                      .map((c) => DropdownMenuItem<dynamic>(
                            value: c,
                            child: Text('สัญญา ${c['contract_number'] ?? c['id']}'),
                          ))
                      .toList(),
                  onChanged: (c) {
                    setState(() {
                      selectedContract = c;
                      fetchHistoryForSelected();
                    });
                  },
                ),
              ),
            ),
          // ปุ่ม advance pay
          if (showAdvancePayButton)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ElevatedButton.icon(
                icon: Icon(Icons.payments_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: Text(
                  'ชำระงวดค้างทันทีด้วย Advance (${advancePayment.toStringAsFixed(2)} บาท)',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                ),
                onPressed: _payInstallmentWithAdvance,
              ),
            ),
          // Dashboard Card (3 แถวหลัก)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: _accent(context), size: 28),
                    SizedBox(width: 8),
                    Text('เลขสัญญา ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
                    Text('${sc['contract_number'] ?? '-'}',
                        style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: _accent(context), fontSize: 18)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money_rounded, color: Colors.amber, size: 26),
                    SizedBox(width: 8),
                    Text('ผ่อนทอง: ', style: GoogleFonts.prompt(fontSize: 16, color: Colors.black54)),
                    Text('${sc['gold_amount'] ?? '-'} บาท', style: GoogleFonts.prompt(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
                  ],
                ),
                if (advancePayment > 0) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blue, size: 22),
                      SizedBox(width: 6),
                      Text('เงินคงเหลือ (Advance): ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${advancePayment.toStringAsFixed(2)} บาท', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  Text(
                    'เงินเกินนี้จะถูกนำไปหักยอดผ่อนในวันครบกำหนดอัตโนมัติ',
                    style: GoogleFonts.prompt(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
                Divider(height: 32, thickness: 1, color: Colors.black12.withOpacity(0.13)),
                if (!isSundayToday())
                  _dashboardInfoRow(Icons.event, 'ยอดครบกำหนดชำระวันนี้', '${dueTodayAmount.toStringAsFixed(2)} บาท', _accent(context)),
                _dashboardInfoRow(Icons.warning, 'ยอดค้างชำระ', '${overdueAmount.toStringAsFixed(2)} บาท', Colors.deepOrange),
                _dashboardInfoRow(Icons.payment, 'ยอดครบกำหนดที่ต้องชำระทั้งหมด', '${totalDue.toStringAsFixed(2)} บาท', Colors.amber[900]!),
                Divider(height: 32, thickness: 1, color: Colors.black12.withOpacity(0.13)),
                Text('ชำระแล้วทั้งหมด', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LinearProgressIndicator(
                    value: totalAmount > 0 ? usedForPaid / totalAmount : 0,
                    backgroundColor: Colors.black12,
                    color: Colors.greenAccent,
                    minHeight: 12,
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${usedForPaid.toStringAsFixed(2)} / ${totalAmount.toStringAsFixed(2)} บาท (${percentPaid.toStringAsFixed(2)}%)',
                    style: GoogleFonts.prompt(fontSize: 14, color: Colors.black54),
                  ),
                ),
                Divider(height: 32, thickness: 1, color: Colors.black12.withOpacity(0.13)),
                Text('ระยะเวลาผ่อน: $passedInstallments / $period งวด',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LinearProgressIndicator(
                    value: period > 0 ? passedInstallments / period : 0,
                    backgroundColor: Colors.black12,
                    color: _accent(context),
                    minHeight: 12,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${((passedInstallments / (period == 0 ? 1 : period)) * 100).toStringAsFixed(2)}%',
                      style: GoogleFonts.prompt(fontSize: 14, color: Colors.black54)),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
          Text("ประวัติเติมเงิน (ธุรกรรม)", style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal[800])),
          const SizedBox(height: 10),
          _buildAdvancePaymentHistory(filteredAdvances),
          SizedBox(height: 24),
          Text("ประวัติผ่อนชำระ (เฉพาะงวดที่ถึงปัจจุบัน)", style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.orange[800])),
          const SizedBox(height: 10),
          _buildInstallmentPayments(historyList),
        ],
      ),
    );
  }

  Widget _dashboardInfoRow(IconData icon, String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: valueColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                ),
                Text(
                  value,
                  style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancePaymentHistory(List<Map<String, dynamic>> advances) {
    if (advances.isEmpty) {
      return Center(
        child: Text('ยังไม่มีประวัติเติมเงิน', style: GoogleFonts.prompt(color: Colors.black38)),
      );
    }
    return Column(
      children: advances.map<Widget>((tx) {
        final dt = formatDate(tx['created_at']);
        final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: ListTile(
            leading: Icon(Icons.account_balance_wallet, color: Colors.teal[700], size: 28),
            title: Text('เติมเงิน: ${amount.toStringAsFixed(2)} บาท', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.teal[900])),
            subtitle: Text('เมื่อ: $dt', style: GoogleFonts.prompt(fontSize: 14)),
            trailing: Icon(Icons.receipt, color: Colors.teal[700]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstallmentPayments(List<Map<String, dynamic>> historyList) {
    if (historyList.isEmpty) {
      return Center(
        child: Text('ยังไม่มีประวัติผ่อนงวด', style: GoogleFonts.prompt(color: Colors.black38)),
      );
    }
    return Column(
      children: historyList.map((tx) {
        Color color = tx['status'] == 'paid' ? Colors.green : Colors.red[400]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: tx['status'] == 'paid' ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
          ),
          child: ListTile(
            leading: Icon(
              tx['status'] == 'paid' ? Icons.check_circle : Icons.access_time,
              color: color,
              size: 28,
            ),
            title: Text(
              'ผ่อนงวด: ${(tx['amount'] ?? 0).toStringAsFixed(2)} บาท',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: color),
            ),
            subtitle: Text(
              'วันที่ครบกำหนด: ${formatDate(tx['payment_due_date']) != "-" 
                ? formatDate(tx['payment_due_date']) 
                : formatDate(tx['created_at'])}',
              style: GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
            ),
            trailing: Text(
              tx['status'] == 'paid' ? 'ชำระแล้ว' : 'ค้าง',
              style: GoogleFonts.prompt(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
