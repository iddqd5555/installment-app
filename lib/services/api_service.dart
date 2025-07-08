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

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return token ?? '';
  }

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

  // ดึงข้อมูล installments จากหลังบ้าน
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


  Future<bool> login(String phone, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<void> updateLocationSilently(double lat, double lng, bool isMocked) async {
    final token = await getToken();
    try {
      final response = await _dio.post(
        '/user/update-location',
        data: {'lat': lat, 'lng': lng, 'is_mocked': isMocked},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Location updated: ${response.statusCode} | ${response.data}");
    } catch (e) {
      print("🚨 GPS update failed: $e");
    }
  }

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
      return response.data;
    } catch (e) {
      print('Dashboard error: $e');
      return null;
    }
  }

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
      return response.data is Map ? response.data : null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

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
      return response.statusCode == 200;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  String getImageUrl(String filename) {
    return '$baseUrl/storage/uploads/$filename';
  }
}
