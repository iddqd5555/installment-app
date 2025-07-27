import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://bg6.1dc.mytemp.website/api'; // เปลี่ยนตาม environment จริง

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ---------- ระบบ PIN ----------
  Future<bool> setPin(String pin) async {
    final token = await getToken();
    final res = await _dio.post(
      '/user/set-pin',
      data: {'pin_code': pin},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return res.data['success'] == true;
  }

  Future<bool> checkPin(String pin) async {
    final token = await getToken();
    final res = await _dio.post(
      '/user/check-pin',
      data: {'pin_code': pin},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return res.data['success'] == true;
  }
  // --------------------------------

  Future<Map<String, dynamic>> getCurrentLocationMap() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      return {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'isMocked': pos.isMocked,
      };
    } catch (_) {
      return {
        'latitude': null,
        'longitude': null,
        'isMocked': null,
      };
    }
  }

  Future<void> updateLocationSilently(double lat, double lng, bool isMocked) async {
    final token = await getToken();
    try {
      await _dio.post(
        '/user/update-location',
        data: {
          'lat': lat,
          'lng': lng,
          'is_mocked': isMocked,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Update location error: $e');
    }
  }

  Future<String?> getPublicIP() async {
    return '127.0.0.1';
  }

  Future<Map<String, dynamic>> getDashboardData() async {
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
      if (response.data is Map && response.data['contracts'] is List) {
        return response.data;
      }
      if (response.data is List) {
        return {'contracts': response.data};
      }
      return {'contracts': []};
    } catch (e) {
      print('Dashboard error: $e');
      return {'contracts': []};
    }
  }

  // ======= Advance =======
  Future<bool> payInstallmentWithAdvance(dynamic contractId) async {
    final token = await getToken();
    try {
      final response = await _dio.post(
        '/installments/$contractId/pay-from-advance',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('payInstallmentWithAdvance error: $e');
      return false;
    }
  }
  // =======================

  Future<Map<String, dynamic>> uploadSlip({
    int? installmentRequestId,
    required File slipFile,
  }) async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();

    FormData formData = FormData();

    if (installmentRequestId != null) {
      formData.fields.add(MapEntry('installment_request_id', installmentRequestId.toString()));
    }

    formData.files.add(MapEntry('slip', await MultipartFile.fromFile(slipFile.path)));
    if (gps['latitude'] != null) formData.fields.add(MapEntry('lat', gps['latitude'].toString()));
    if (gps['longitude'] != null) formData.fields.add(MapEntry('lng', gps['longitude'].toString()));
    if (gps['isMocked'] != null) formData.fields.add(MapEntry('is_mocked', '${gps['isMocked']}'));
    if (publicIp != null) formData.fields.add(MapEntry('public_ip', publicIp));

    try {
      final response = await _dio.post(
        '/installment/pay',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'data': response.data};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? response.statusMessage ?? 'Unknown error',
        'errors': response.data['errors'] ?? {},
        'statusCode': response.statusCode
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

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
      if (response.statusCode == 200 && response.data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', response.data['token']);
        print("TOKEN: ${response.data['token']}");
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  String getImageUrl(String filename) {
    // สำหรับโหลดโลโก้ธนาคาร (storage/app/public/bank-logos)
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return filename;
    return '$baseUrl/storage/$filename';
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    try {
      final response = await _dio.get('/user/profile', options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.statusCode == 200 ? response.data : null;
    } catch (e) {
      print("Get profile error: $e");
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data, {File? idCardImage}) async {
    final token = await getToken();
    try {
      FormData formData = FormData.fromMap(data);
      if (idCardImage != null) {
        formData.files.add(MapEntry('id_card_image', await MultipartFile.fromFile(idCardImage.path)));
      }
      final response = await _dio.post('/profile/update', data: formData, options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.statusCode == 200 && (response.data['success'] == true || response.data['status'] == true);
    } catch (e) {
      print("Update profile error: $e");
      return false;
    }
  }

  Future<List<dynamic>> getInstallmentRequests() async {
    final token = await getToken();
    try {
      final gps = await getCurrentLocationMap();
      final publicIp = await getPublicIP();
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
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
      if (response.data is Map && response.data['data'] is List) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Get Installment Requests Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserPaymentHistory() async {
    final token = await getToken();
    final response = await _dio.get(
      '/installment/user-history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPaymentHistory(int installmentRequestId) async {
    final token = await getToken();
    final response = await _dio.get(
      '/installment/history',
      queryParameters: {'installment_request_id': installmentRequestId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getAllAdvancePayments() async {
    final token = await getToken();
    final response = await _dio.get(
      '/advance-payments/all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final list = response.data['advance_payments'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  // ===== Notification Functions =====

  Future<Map<String, dynamic>> getNotifications({int page = 1, int perPage = 30}) async {
    final token = await getToken();
    final res = await _dio.get(
      '/notifications',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    return res.data;
  }

  Future markNotificationAsRead(int id) async {
    final token = await getToken();
    await _dio.patch(
      '/notifications/$id/read',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future markAllNotificationsAsRead() async {
    final token = await getToken();
    await _dio.post(
      '/notifications/mark-all-read',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ======= ฟังก์ชันลืมรหัสผ่าน/OTP =======
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post('/forgot-password/send-otp', data: {'email': email});
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'ส่ง OTP ไม่สำเร็จ'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post('/forgot-password/verify-otp', data: {'email': email, 'otp': otp});
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': response.data['message'] ?? 'OTP ไม่ถูกต้อง'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password) async {
    try {
      final response = await _dio.post('/forgot-password/reset', data: {
        'email': email,
        'otp': otp,
        'password': password,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadUserDocument(File file, {String? filename}) async {
    final token = await getToken();
    try {
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path, filename: filename ?? file.path.split('/').last),
      });
      final res = await _dio.post(
        '/user/upload-document',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : {'success': false};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================
  // ดึงบัญชีธนาคารที่เปิดใช้งานจากหลังบ้าน (สำหรับ PaymentScreen)
  Future<Map<String, dynamic>> getCompanyBanks() async {
    try {
      final res = await _dio.get('/company-banks');
      return res.data is Map ? Map<String, dynamic>.from(res.data) : {};
    } catch (e) {
      return {};
    }
  }
}
