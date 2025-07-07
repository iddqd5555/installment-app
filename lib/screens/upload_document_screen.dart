import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class UploadDocumentScreen extends StatefulWidget {
  final int installmentId;
  UploadDocumentScreen({required this.installmentId});

  @override
  _UploadDocumentScreenState createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  XFile? _image;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  Future<void> uploadDocument() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    FormData formData = FormData.fromMap({
      'document_image': await MultipartFile.fromFile(_image!.path),
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['Accept'] = 'application/json';

    final response = await dio.post(
      'http://192.168.1.43:8000/api/installments/${widget.installmentId}/upload-documents',
      data: formData,
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("อัปโหลดสำเร็จ!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปโหลด")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('อัปโหลดเอกสารและตำแหน่ง'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('ยังไม่ได้เลือกรูปภาพ')
                : Image.file(
                    File(_image!.path),
                    height: 200,
                  ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera),
              label: Text('ถ่ายภาพ'),
              onPressed: pickImage,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: isLoading ? CircularProgressIndicator() : Icon(Icons.upload),
              label: Text(isLoading ? 'กำลังอัปโหลด...' : 'อัปโหลดเอกสาร'),
              onPressed: _image == null || isLoading ? null : uploadDocument,
            ),
          ],
        ),
      ),
    );
  }
}
