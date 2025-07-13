import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InstallmentDashboardScreen extends StatefulWidget {
  final int installmentRequestId;

  const InstallmentDashboardScreen({super.key, required this.installmentRequestId});

  @override
  State<InstallmentDashboardScreen> createState() => _InstallmentDashboardScreenState();
}

class _InstallmentDashboardScreenState extends State<InstallmentDashboardScreen> {
  bool _isLoading = true;
  bool _isPaying = false;
  List<dynamic> _history = [];
  List<dynamic> _overdues = [];
  File? _slipFile;
  List<String> _selectedDates = [];
  double _payAmount = 0;
  String? _resultMsg;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final uri = Uri.parse('http://192.168.1.41:8000/api/installment/history?installment_request_id=${widget.installmentRequestId}');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final history = data['history'] as List<dynamic>;
      _history = history;
      _overdues = history
          .where((p) => p['payment_status'] != 'paid' && DateTime.parse(p['payment_due_date']).isBefore(DateTime.now()))
          .toList();
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _resultMsg = 'โหลดข้อมูลไม่สำเร็จ';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _slipFile = File(picked.path));
  }

  Future<void> _submitPayment() async {
    if (_slipFile == null || _selectedDates.isEmpty) return;
    setState(() {
      _isPaying = true;
      _resultMsg = null;
    });
    final uri = Uri.parse('http://192.168.1.41:8000/api/installment/pay');
    final req = http.MultipartRequest('POST', uri)
      ..fields['installment_request_id'] = widget.installmentRequestId.toString()
      ..fields['amount_paid'] = _payAmount.toString();
    for (final d in _selectedDates) {
      req.fields['pay_for_dates[]'] = d;
    }
    req.files.add(await http.MultipartFile.fromPath('slip', _slipFile!.path));

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    if (resp.statusCode == 200) {
      setState(() {
        _resultMsg = 'ส่งสลิปสำเร็จ รอแอดมินตรวจสอบ';
        _slipFile = null;
        _selectedDates.clear();
        _payAmount = 0;
        _isPaying = false;
      });
      _fetchHistory();
    } else {
      setState(() {
        _resultMsg = 'เกิดข้อผิดพลาด: $body';
        _isPaying = false;
      });
    }
  }

  Widget _buildOverdueWarning() {
    if (_overdues.isEmpty) return Container();
    final latest = _overdues.first;
    DateTime dueDate = DateTime.parse(latest['payment_due_date']);
    int daysLate = DateTime.now().difference(dueDate).inDays;
    String warn = daysLate > 2
        ? "⚠️ ค้างชำระเกิน 2 วันแล้ว กรุณาชำระด่วน!"
        : "⚠️ มีงวดค้างชำระ กรุณาชำระก่อนวันที่ ${DateFormat('dd/MM/yyyy').format(dueDate.add(const Duration(days: 2)))}";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
      child: Text(warn, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentSection() {
    final unpaid = _history.where((p) => p['payment_status'] != 'paid').toList();
    if (unpaid.isEmpty) {
      return const Text('งวดทั้งหมดชำระครบแล้ว');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("เลือกวัน/งวดที่ต้องการผ่อนจ่าย", style: TextStyle(fontWeight: FontWeight.bold)),
        ...unpaid.map((pay) {
          DateTime due = DateTime.parse(pay['payment_due_date']);
          final isSelected = _selectedDates.contains(pay['payment_due_date']);
          final isLate = DateTime.now().isAfter(due);
          return CheckboxListTile(
            title: Text(
              "งวดวันที่ ${DateFormat('dd/MM/yyyy').format(due)}"
              " | ยอด ${pay['amount'] ?? '-'}"
              " | สถานะ ${pay['payment_status']}",
              style: isLate ? const TextStyle(color: Colors.red) : null,
            ),
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedDates.add(pay['payment_due_date']);
                } else {
                  _selectedDates.remove(pay['payment_due_date']);
                }
                // คำนวณยอดรวม
                _payAmount = unpaid
                    .where((p) => _selectedDates.contains(p['payment_due_date']))
                    .fold(0.0, (sum, p) => sum + (double.tryParse(p['amount'].toString()) ?? 0.0));
              });
            },
          );
        }).toList(),
        const SizedBox(height: 10),
        Text("ยอดที่ต้องชำระ: ${_payAmount.toStringAsFixed(2)} บาท", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.yellow[100],
          child: ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.orange),
            title: const Text("โอนเงินเข้าบัญชีบริษัท"),
            subtitle: const Text("ชื่อบัญชี: วิสดอม โกลด์ กรุ้ป จำกัด\nเลขที่บัญชี: 865-1-00811-6 (กสิกรไทย)"),
          ),
        ),
        const SizedBox(height: 8),
        _slipFile == null
            ? const Text("ยังไม่ได้เลือกรูปสลิป")
            : Image.file(_slipFile!, width: 200),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('เลือก/ถ่ายรูปสลิป'),
          onPressed: _pickSlip,
        ),
        const SizedBox(height: 8),
        _isPaying
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: (_slipFile != null && _selectedDates.isNotEmpty && _payAmount > 0) ? _submitPayment : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("ส่งสลิป"),
              ),
        if (_resultMsg != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_resultMsg!, style: TextStyle(color: _resultMsg!.contains('สำเร็จ') ? Colors.green : Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ข้อมูลผ่อนและชำระเงิน")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverdueWarning(),
                _buildPaymentSection(),
              ],
            ),
    );
  }
}
