import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_detail_screen.dart';
import 'payment_history_screen.dart';
import 'pin_screen.dart'; // <-- เพิ่ม import
import '../services/api_service.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});
  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
    });
    final data = await apiService.getProfile();
    setState(() {
      profile = data;
      isLoading = false;
    });
  }

  Future<void> handleLogout() async {
    await apiService.clearToken();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Color _accent(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "โปรไฟล์ของฉัน",
          style: GoogleFonts.prompt(color: _accent(context), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _accent(context)),
            tooltip: 'Reload',
            onPressed: fetchProfile,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProfile,
              child: ListView(
                children: [
                  if (profile != null) ...[
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.09),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${profile?['first_name'] ?? ""} ${profile?['last_name'] ?? ""}",
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 19, color: _accent(context)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "เบอร์โทร: ${profile?['phone'] ?? ""}",
                            style: GoogleFonts.prompt(color: Colors.black54, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  _profileMenuItem(
                    icon: Icons.person_rounded,
                    color: Colors.orange,
                    label: "ข้อมูลส่วนตัว",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileDetailScreen()),
                      ).then((v) => fetchProfile());
                    },
                  ),
                  _profileMenuItem(
                    icon: Icons.history,
                    color: Colors.blueAccent,
                    label: "ประวัติการชำระเงิน",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                      );
                    },
                  ),
                  // ===== เพิ่มปุ่มเปลี่ยน PIN ที่นี่ =====
                  _profileMenuItem(
                    icon: Icons.lock_reset_rounded,
                    color: _accent(context),
                    label: "เปลี่ยนรหัส PIN",
                    onTap: () async {
                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)),
                      );
                      if (ok == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("เปลี่ยนรหัส PIN สำเร็จ", style: GoogleFonts.prompt()),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  _profileMenuItem(
                    icon: Icons.assignment,
                    color: Colors.teal,
                    label: "ข้อตกลงการใช้งาน",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: Text("ข้อตกลงการใช้งาน", style: GoogleFonts.prompt(color: _accent(context), fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: Text(
                              '''
1. ผู้ใช้งานต้องใช้ข้อมูลที่ถูกต้องและตรงกับความเป็นจริงในการสมัครและใช้บริการ
2. ห้ามใช้บริการนี้ในการกระทำที่ผิดกฎหมาย หรือฉ้อโกงในทุกรูปแบบ
3. การชำระเงิน การผ่อนทอง หรือการเติมเงินทุกครั้ง ผู้ใช้งานต้องตรวจสอบรายละเอียดก่อนทำรายการ
4. บริษัทขอสงวนสิทธิ์ในการระงับการให้บริการหรือปิดบัญชีผู้ใช้งานที่มีการกระทำผิดข้อตกลง โดยไม่ต้องแจ้งล่วงหน้า
5. การเปลี่ยนแปลงข้อตกลง บริษัทสามารถปรับปรุงข้อตกลงนี้ได้โดยจะแจ้งให้ทราบผ่านช่องทางที่เหมาะสม
6. หากพบปัญหาในการใช้งาน กรุณาติดต่อฝ่ายบริการลูกค้าโดยเร็วที่สุด
                              ''',
                              style: GoogleFonts.prompt(color: Colors.black87),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text("ปิด", style: GoogleFonts.prompt(color: _accent(context))),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _profileMenuItem(
                    icon: Icons.privacy_tip,
                    color: Colors.green,
                    label: "นโยบายความเป็นส่วนตัว",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: Text("นโยบายความเป็นส่วนตัว", style: GoogleFonts.prompt(color: _accent(context), fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: Text(
                              '''
1. บริษัทให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้งาน ข้อมูลส่วนบุคคลจะถูกเก็บรักษาอย่างปลอดภัย
2. ข้อมูลที่จัดเก็บ เช่น ชื่อ-สกุล เบอร์โทร อีเมล ที่อยู่ และประวัติการทำธุรกรรม จะใช้เพื่อยืนยันตัวตนและให้บริการเท่านั้น
3. บริษัทจะไม่เปิดเผยหรือขายข้อมูลส่วนตัวของผู้ใช้งานให้กับบุคคลที่สาม ยกเว้นในกรณีที่กฎหมายกำหนด
4. ผู้ใช้งานสามารถติดต่อขอแก้ไข หรือขอลบข้อมูลส่วนตัวของตนเองได้ตลอดเวลา
5. เว็บไซต์/แอปนี้มีการใช้คุกกี้เพื่อปรับปรุงประสบการณ์ผู้ใช้
6. การใช้งานระบบถือว่าผู้ใช้ยินยอมตามนโยบายความเป็นส่วนตัวนี้ทุกประการ
                              ''',
                              style: GoogleFonts.prompt(color: Colors.black87),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text("ปิด", style: GoogleFonts.prompt(color: _accent(context))),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  _profileMenuItem(
                    icon: Icons.logout,
                    color: Colors.red,
                    label: "ออกจากระบบ",
                    onTap: () async {
                      await handleLogout();
                    },
                    isLogout: true,
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isLogout ? Colors.red.withOpacity(0.10) : Theme.of(context).cardColor,
        leading: Icon(icon, color: color, size: 27),
        title: Text(label, style: GoogleFonts.prompt(
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
        )),
        onTap: onTap,
      ),
    );
  }
}
