import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int installmentRequestId;
  const PaymentScreen({Key? key, required this.installmentRequestId}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? slipFile;
  bool isUploading = false;
  String? message;

  List<Map<String, dynamic>> banks = [];
  bool isLoadingBank = true;

  @override
  void initState() {
    super.initState();
    if (widget.installmentRequestId == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            message = "❌ ไม่พบเลขสัญญาหรือระบบขัดข้อง กรุณากลับไปเลือกใหม่";
          });
        }
      });
    } else {
      fetchBanks();
    }
  }

  Future<void> fetchBanks() async {
    setState(() => isLoadingBank = true);
    try {
      final res = await ApiService().getCompanyBanks();
      if (!mounted) return;
      setState(() {
        banks = (res['banks'] as List?)
            ?.where((b) => b['is_active'] == 1 || b['is_active'] == true)
            .map((b) => Map<String, dynamic>.from(b))
            .toList() ?? [];
        isLoadingBank = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        banks = [];
        isLoadingBank = false;
      });
    }
  }

  Future<void> pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => slipFile = File(picked.path));
    }
  }

  Future<void> uploadSlip() async {
    print("[DEBUG] installmentRequestId: ${widget.installmentRequestId}");
    if (widget.installmentRequestId == 0 || widget.installmentRequestId == null) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        message = "❌ ไม่พบเลขสัญญา (installment_request_id) กรุณาเลือกสัญญาใหม่!";
      });
      return;
    }

    if (slipFile == null || isUploading) return;
    setState(() {
      isUploading = true;
      message = null;
    });

    try {
      final result = await ApiService().uploadSlip(
        slipFile: slipFile!,
        installmentRequestId: widget.installmentRequestId,
      );

      if (!mounted) return;
      setState(() {
        isUploading = false;
        if (result['used'] == true) {
          message = "❌ สลิปนี้ถูกใช้งานแล้ว คุณไม่สามารถอัพโหลดสลิปซ้ำได้";
        } else if (result['success'] == true) {
          message = "✅ อัปโหลดสลิปสำเร็จ! ระบบจะตรวจสอบและหักยอดให้โดยอัตโนมัติ";
          slipFile = null;
        } else {
          message = "อัปโหลดล้มเหลว: ${result['message'] ?? "ไม่ทราบสาเหตุ"}";
        }
      });

      if (!mounted) return;

      // SnackBar และ pop แบบปลอดภัย
      if (result['used'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ สลิปนี้ถูกใช้งานแล้ว")),
          );
        }
      } else if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("อัปโหลดสลิปสำเร็จ!")),
          );
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
        // ห้าม showSnackBar ต่อหลัง pop
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? "เกิดข้อผิดพลาด")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        message = "เกิดข้อผิดพลาด: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message!)),
        );
      }
    }
  }

  Widget _buildBankCard() {
    final accent = Theme.of(context).colorScheme.primary;

    if (!isLoadingBank && banks.isNotEmpty) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shadowColor: accent.withOpacity(0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.push_pin, color: accent, size: 22),
                  SizedBox(width: 6),
                  Text('ข้อมูลบัญชีสำหรับโอนเงิน',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: accent, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(thickness: 1, color: Colors.black12),
              ...banks.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    if ((b['logo'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ClipOval(
                          child: Image.network(
                            ApiService().getImageUrl(b['logo']),
                            width: 32, height: 32, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.account_balance),
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ธนาคาร: ${b['bank_name']}', style: GoogleFonts.prompt()),
                        Text('ชื่อบัญชี: ${b['account_name']}', style: GoogleFonts.prompt()),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'เลขที่บัญชี: ',
                                style: GoogleFonts.prompt(fontWeight: FontWeight.normal, color: Colors.black87),
                              ),
                              TextSpan(
                                text: b['account_number'] ?? '',
                                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                              ),
                              if (b['is_default'] == true || b['is_default'] == 1)
                                WidgetSpan(child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.star, color: Colors.amber, size: 17),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      );
    }

    // fallback
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: accent.withOpacity(0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.push_pin, color: accent, size: 22),
                SizedBox(width: 6),
                Text('ข้อมูลบัญชีสำหรับโอนเงิน',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: accent, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(thickness: 1, color: Colors.black12),
            Text('ธนาคาร: กสิกรไทย', style: GoogleFonts.prompt()),
            Text('ชื่อบัญชี: บริษัท วิสดอม โกลด์ กรุ้ป จำกัด', style: GoogleFonts.prompt()),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'เลขที่บัญชี: ',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.normal, color: Colors.black87),
                  ),
                  TextSpan(
                    text: '865-1-00811-6',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('อัปโหลดสลิปชำระเงิน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: accent)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            isLoadingBank
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: CircularProgressIndicator(),
                  ))
                : _buildBankCard(),
            const SizedBox(height: 28),
            Text(
              "อัปโหลดสลิปโอนเงินเข้าบริษัท (ระบบจะตรวจสอบและหักยอดให้โดยอัตโนมัติ)",
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            slipFile == null
                ? Text("ยังไม่ได้เลือกรูปสลิป", style: GoogleFonts.prompt(color: Colors.grey))
                : Image.file(slipFile!, height: 180),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : pickSlip,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("เลือกรูปสลิป"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: accent,
                      textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUploading || slipFile == null || widget.installmentRequestId == 0
                        ? null
                        : uploadSlip,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: (isUploading || slipFile == null || widget.installmentRequestId == 0)
                        ? Colors.grey[300]
                        : secondary,
                      textStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text("ส่งสลิป"),
                  ),
                ),
              ],
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message!,
                  style: GoogleFonts.prompt(
                    color: message!.contains("สำเร็จ") ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
