import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.1.43:8000/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
  }

  // ล็อกอิน
  Future<bool> login(String phone, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ดึงข้อมูล installments (รายการสัญญาทั้งหมด)
  Future<List<dynamic>> getInstallments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await _dio.get('/installments',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

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

  // ✅ เพิ่มเมธอดดึงข้อมูล dashboard (ที่ต้องเพิ่มชัดเจนที่สุดตอนนี้)
  Future<dynamic> getDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await _dio.get('/dashboard-data',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

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

  Future<List<dynamic>> getPaymentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await _dio.get('/payments',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return [];
      }
    } catch (e) {
      print('Connection Error: $e');
      return [];
    }
  }

}
