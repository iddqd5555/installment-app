import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isEditing = false;
  bool isSubmitting = false;
  String? errorMessage;

  Map<String, dynamic>? profile;
  File? idCardImage;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  fetchProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await apiService.getProfile();
      print("GET PROFILE RESPONSE: $data");
      if (data == null) {
        setState(() {
          errorMessage = "โหลดข้อมูลโปรไฟล์ไม่สำเร็จ";
          isLoading = false;
        });
        return;
      }
      setState(() {
        profile = Map<String, dynamic>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาดขณะโหลดข้อมูล: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        idCardImage = File(picked.path);
      });
    }
  }

  saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    Map<String, dynamic> updatedData = {
      "first_name": profile?['first_name'] ?? "",
      "last_name": profile?['last_name'] ?? "",
      "email": profile?['email'] ?? "",
      "phone": profile?['phone'] ?? "",
      "address": profile?['address'] ?? "",
      "date_of_birth": profile?['date_of_birth'] ?? "",
      "gender": profile?['gender'] ?? "",
    };

    bool success = await apiService.updateProfile(updatedData, idCardImage: idCardImage);
    if (success) {
      fetchProfile();
      setState(() {
        isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกสำเร็จ")),
        );
      }
    } else {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาดขณะบันทึกข้อมูล";
      });
    }
    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("โปรไฟล์ของฉัน")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProfile,
                child: const Text("โหลดใหม่"),
              )
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("โปรไฟล์ของฉัน")),
        body: const Center(
          child: Text("ไม่พบข้อมูลโปรไฟล์"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์ของฉัน"),
        actions: [
          isEditing
              ? IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: isSubmitting ? null : saveProfile,
                )
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => isEditing = true),
                )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // รูปบัตรประชาชน
            Center(
              child: InkWell(
                onTap: isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: idCardImage != null
                      ? FileImage(idCardImage!)
                      : ((profile?['id_card_image'] ?? '').toString().isNotEmpty)
                          ? NetworkImage(apiService.getImageUrl(profile?['id_card_image']))
                          : const AssetImage("assets/images/idcard_placeholder.png") as ImageProvider,
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              initialValue: profile?['first_name'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "ชื่อจริง"),
              validator: (v) => v == null || v.isEmpty ? "กรุณากรอกชื่อจริง" : null,
              onChanged: (v) => setState(() => profile?['first_name'] = v),
            ),
            TextFormField(
              initialValue: profile?['last_name'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "นามสกุล"),
              validator: (v) => v == null || v.isEmpty ? "กรุณากรอกนามสกุล" : null,
              onChanged: (v) => setState(() => profile?['last_name'] = v),
            ),
            TextFormField(
              initialValue: profile?['phone'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
              validator: (v) => v == null || v.isEmpty ? "กรุณากรอกเบอร์โทร" : null,
              onChanged: (v) => setState(() => profile?['phone'] = v),
            ),
            TextFormField(
              initialValue: profile?['email'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "อีเมล"),
              validator: (v) => v == null || v.isEmpty ? "กรุณากรอกอีเมล" : null,
              onChanged: (v) => setState(() => profile?['email'] = v),
            ),
            TextFormField(
              initialValue: profile?['address'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "ที่อยู่"),
              onChanged: (v) => setState(() => profile?['address'] = v),
            ),
            TextFormField(
              initialValue: profile?['date_of_birth'] ?? "",
              enabled: isEditing,
              decoration: const InputDecoration(labelText: "วันเกิด (YYYY-MM-DD)"),
              onChanged: (v) => setState(() => profile?['date_of_birth'] = v),
            ),
            DropdownButtonFormField<String>(
              value: profile?['gender'] ?? "",
              items: const [
                DropdownMenuItem(child: Text("ชาย"), value: "ชาย"),
                DropdownMenuItem(child: Text("หญิง"), value: "หญิง"),
                DropdownMenuItem(child: Text("อื่นๆ"), value: "อื่นๆ"),
              ],
              decoration: const InputDecoration(labelText: "เพศ"),
              onChanged: isEditing
                  ? (v) {
                      setState(() {
                        profile?['gender'] = v;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
