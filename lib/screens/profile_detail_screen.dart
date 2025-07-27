import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userDocuments = [];

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _idCard = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProfile();
      if (data != null) {
        _firstName.text = data['first_name'] ?? '';
        _lastName.text  = data['last_name'] ?? '';
        _phone.text     = data['phone'] ?? '';
        _idCard.text    = data['id_card_number'] ?? '';
        _email.text     = data['email'] ?? '';
        _address.text   = data['address'] ?? '';
        if (data['documents'] != null && data['documents'] is List) {
          _userDocuments = List<Map<String, dynamic>>.from(data['documents']);
        }
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!', style: GoogleFonts.prompt())),
      );
    }
  }

  Future<void> _pickAndUploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _uploadDocument(file, result.files.single.name);
    }
  }

  Future<void> _uploadDocument(File file, String filename) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('กำลังอัปโหลด...', style: GoogleFonts.prompt()),
      duration: Duration(seconds: 2),
    ));
    try {
      final resp = await ApiService().uploadUserDocument(file, filename: filename);
      if (!mounted) return;
      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดสำเร็จ', style: GoogleFonts.prompt())),
        );
        _loadProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดล้มเหลว: ${resp['message'] ?? ''}', style: GoogleFonts.prompt())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดล้มเหลว', style: GoogleFonts.prompt())),
      );
    }
  }

  Widget _documentsList() {
    if (_userDocuments.isEmpty) {
      return Text('ยังไม่มีเอกสารที่อัปโหลด', style: GoogleFonts.prompt());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _userDocuments.map((doc) {
        final isImage = doc['url'] != null && (doc['url'].endsWith('.jpg') || doc['url'].endsWith('.jpeg') || doc['url'].endsWith('.png'));
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: isImage
              ? Image.network(doc['url'], width: 40, height: 40, fit: BoxFit.cover)
              : Icon(Icons.insert_drive_file, size: 40, color: Colors.grey[600]),
            title: Text(doc['name'] ?? 'ไม่ระบุชื่อไฟล์', style: GoogleFonts.prompt()),
            subtitle: Text(doc['uploaded_at'] ?? '', style: GoogleFonts.prompt(fontSize: 12)),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text("ข้อมูลส่วนตัว", style: GoogleFonts.prompt(color: accent, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[500])
                        : null,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstName,
                  decoration: InputDecoration(labelText: "ชื่อจริง", prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อจริง' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastName,
                  decoration: InputDecoration(labelText: "นามสกุล", prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  decoration: InputDecoration(labelText: "เบอร์โทรศัพท์", prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.length < 9 ? 'กรุณากรอกเบอร์โทรให้ถูกต้อง' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idCard,
                  decoration: InputDecoration(labelText: "เลขบัตรประชาชน", prefixIcon: Icon(Icons.badge)),
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  validator: (v) => v == null || v.length != 13 ? 'กรุณากรอกเลขบัตร 13 หลัก' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(labelText: "อีเมล", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'กรุณากรอกอีเมลให้ถูกต้อง' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(labelText: "ที่อยู่", prefixIcon: Icon(Icons.home)),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                ),
                const SizedBox(height: 32),

                // ==== ปุ่มอัปโหลดเอกสาร ====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("เอกสารเพิ่มเติม", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 10),
                _documentsList(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.upload_file, color: accent),
                    label: Text("อัปโหลดเอกสารเพิ่มเติม", style: GoogleFonts.prompt(color: accent, fontWeight: FontWeight.bold)),
                    onPressed: _pickAndUploadDocument,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: accent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==== ปุ่มบันทึก ====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text("บันทึกข้อมูล", style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.prompt(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
