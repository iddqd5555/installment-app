import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.1.36:8000/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
  }

  // ดึง token ที่ save ไว้
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("GET TOKEN FROM PREF: $token");
    return token ?? '';
  }

  // ========== เพิ่ม ฟังก์ชันนี้ (จะได้ใช้กับทุก API) ==========
  Future<Map<String, dynamic>> getCurrentLocationMap() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      return {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'isMocked': pos.isMocked,
      };
    } catch (e) {
      return {
        'latitude': null,
        'longitude': null,
        'isMocked': null,
      };
    }
  }
  // ===========================================================

  // LOGIN/REGISTER (debug log + error message)
  Future<bool> login(String phone, String password) async {
    try {
      print("API LOGIN: $phone / $password");
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'password': password,
      });

      print("API LOGIN RESPONSE: ${response.statusCode} | ${response.data}");

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        print("TOKEN SAVED: $token");
        return true;
      }
      print("LOGIN FAIL: ${response.statusCode} | ${response.data}");
      return false;
    } catch (e) {
      print("API LOGIN ERROR: $e");
      return false;
    }
  }

  // ========== ตัวอย่างการใช้งานแนบ GPS ==========
  Future<List<dynamic>> getInstallments() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    try {
      final response = await _dio.get(
        '/installments',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
        },
      );
      print("API /installments RESPONSE: ${response.statusCode} | ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error from API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Connection Error: $e');
      return [];
    }
  }

  // ทุก API สำคัญควรแนบ GPS เช่นนี้
  Future<dynamic> getDashboardData() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    try {
      final response = await _dio.get(
        '/dashboard-data',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
        },
      );
      print("API /dashboard-data RESPONSE: ${response.statusCode} | ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
  }

  // เหมือนเดิมสำหรับ getPaymentHistory(), getProfile(), updateProfile() —> เพิ่ม queryParameters หรือแนบ GPS ใน formData ได้เหมือนกัน

  // PROFILE
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    try {
      final response = await _dio.get(
        '/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
        },
      );
      print("API /user/profile RESPONSE: ${response.statusCode} | ${response.data}");
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else if (response.data is String) {
          return jsonDecode(response.data);
        }
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // อัปเดตโปรไฟล์ (พร้อมอัปโหลดไฟล์)
  Future<bool> updateProfile(
    Map<String, dynamic> data, {
    File? idCardImage,
  }) async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    FormData formData = FormData.fromMap({
      ...data,
      if (idCardImage != null)
        'id_card_image': await MultipartFile.fromFile(
          idCardImage.path,
          filename: idCardImage.path.split('/').last,
        ),
      'lat': gps['latitude'],
      'lng': gps['longitude'],
      'is_mocked': gps['isMocked'],
    });

    try {
      final response = await _dio.post(
        '/user/profile/update',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      print("API /user/profile/update RESPONSE: ${response.statusCode} | ${response.data}");
      return response.statusCode == 200;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  // GET IMAGE URL (สำหรับรูปโปรไฟล์ที่เป็นไฟล์)
  String getImageUrl(String filename) {
    return 'http://192.168.1.36:8000/storage/uploads/$filename';
  }
}
