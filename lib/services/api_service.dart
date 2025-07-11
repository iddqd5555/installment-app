import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.1.151:8000/api'; // เปลี่ยนตรงนี้ถ้า server เปลี่ยน

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
  }

  // ดึง token ที่ login ได้ (เก็บไว้ในเครื่อง)
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return token ?? '';
  }

  // ดึงพิกัด GPS ปัจจุบัน (lat, lng, isMocked)
  Future<Map<String, dynamic>> getCurrentLocationMap() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      return {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'isMocked': pos.isMocked,
      };
    } catch (e) {
      print('GPS error: $e');
      return {
        'latitude': null,
        'longitude': null,
        'isMocked': null,
      };
    }
  }

  // ดึง Public IP จริง (IP ที่ออกอินเทอร์เน็ตจริง)
  Future<String?> getPublicIP() async {
    try {
      final response = await Dio().get('https://api.ipify.org?format=json');
      print('🌐 Public IP: ${response.data['ip']}');
      return response.data['ip'];
    } catch (e) {
      print("Cannot get public IP: $e");
      return null;
    }
  }

  // GET Installments (แนบ GPS + public IP ไปด้วย)
  Future<List<dynamic>> getInstallments() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();
    try {
      final response = await _dio.get(
        '/installments',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
          'public_ip': publicIp,
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

  // Login (POST) + ส่งเวลา UTC + debug error
  Future<bool> login(String phone, String password) async {
    try {
      final publicIp = await getPublicIP();
      final gps = await getCurrentLocationMap();
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'password': password,
        'client_time': DateTime.now().toUtc().toIso8601String(),
        'public_ip': publicIp,
        'lat': gps['latitude'],
        'lng': gps['longitude'],
        'is_mocked': gps['isMocked'],
      });

      print("API /login RESPONSE: ${response.statusCode} | ${response.data}");

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      if (e is DioException) {
        print("DioException response: ${e.response}");
        print("DioException type: ${e.type}");
        print("DioException message: ${e.message}");
        print("DioException data: ${e.response?.data}");
        print("DioException status: ${e.response?.statusCode}");
      }
      return false;
    }
  }

  // อัปเดตตำแหน่งผู้ใช้ (ส่งไป backend ทุกครั้ง)
  Future<void> updateLocationSilently(double lat, double lng, bool isMocked) async {
    final token = await getToken();
    final publicIp = await getPublicIP();
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    try {
      final response = await _dio.post(
        '/user/update-location',
        data: {
          'lat': lat,
          'lng': lng,
          'is_mocked': isMocked,
          'public_ip': publicIp,
          'client_time': nowUtc,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Location updated: ${response.statusCode} | ${response.data}");
    } catch (e) {
      print("🚨 GPS update failed: $e");
    }
  }

  // Dashboard (GET)
  Future<dynamic> getDashboardData() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();
    try {
      final response = await _dio.get(
        '/dashboard-data',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
          'public_ip': publicIp,
        },
      );
      print("API /dashboard-data RESPONSE: ${response.statusCode} | ${response.data}");
      return response.data;
    } catch (e) {
      print('Dashboard error: $e');
      return null;
    }
  }

  // GET Profile (แนบ GPS + public IP)
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();
    try {
      final response = await _dio.get(
        '/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
          'public_ip': publicIp,
        },
      );
      print("API /user/profile RESPONSE: ${response.statusCode} | ${response.data}");
      return response.data is Map ? response.data : null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // Update Profile (POST + multipart, แนบข้อมูลครบ)
  Future<bool> updateProfile(
    Map<String, dynamic> data, {
    File? idCardImage,
  }) async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();

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
      'public_ip': publicIp,
      'client_time': DateTime.now().toUtc().toIso8601String(),
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

  // สำหรับแสดงรูป profile ที่อัพโหลด
  String getImageUrl(String filename) {
    return '$baseUrl/storage/uploads/$filename';
  }
}
