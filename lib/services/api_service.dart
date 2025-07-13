import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://192.168.1.41:8000/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Accept'] = 'application/json';
  }

  // ====== Token ======
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ====== Location/IP ======
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

  Future<String?> getPublicIP() async {
    return '127.0.0.1';
  }

  // ====== Upload Slip ======
  Future<bool> uploadSlip({
    required int installmentRequestId,
    required List<String> payForDates,
    required double amountPaid,
    required File slipFile,
  }) async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();

    FormData formData = FormData();
    formData.fields
      ..add(MapEntry('installment_request_id', installmentRequestId.toString()))
      ..add(MapEntry('amount_paid', amountPaid.toString()))
      ..add(MapEntry('client_time', DateTime.now().toUtc().toIso8601String()));
    for (final date in payForDates) {
      formData.fields.add(MapEntry('pay_for_dates[]', date));
    }
    formData.files.add(MapEntry('slip', await MultipartFile.fromFile(slipFile.path)));
    if (gps['latitude'] != null) formData.fields.add(MapEntry('lat', gps['latitude'].toString()));
    if (gps['longitude'] != null) formData.fields.add(MapEntry('lng', gps['longitude'].toString()));
    if (gps['isMocked'] != null) formData.fields.add(MapEntry('is_mocked', '${gps['isMocked']}'));
    if (publicIp != null) formData.fields.add(MapEntry('public_ip', publicIp));

    // ====== เพิ่มตรงนี้ ======
    print('UPLOAD URL: ${_dio.options.baseUrl}/installment/pay');
    print('Token: $token');
    // =========================

    try {
      final response = await _dio.post(
        '/installment/pay',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );
      print('UPLOAD RESPONSE: ${response.statusCode} ${response.data}');
      return response.statusCode == 200 && (response.data['success'] == true);
    } catch (e) {
      print('Upload Slip Error: $e');
      return false;
    }
  }

  // ====== Confirm QR Payment ======
  Future<bool> confirmQrPayment({
    required int installmentPaymentId,
    required String qrRef,
    required double amountPaid,
  }) async {
    final token = await getToken();
    final gps = await getCurrentLocationMap();
    final publicIp = await getPublicIP();

    try {
      final response = await _dio.post(
        '/confirm-qr',
        data: {
          'installment_payment_id': installmentPaymentId,
          'qr_ref': qrRef,
          'amount_paid': amountPaid,
          'lat': gps['latitude'],
          'lng': gps['longitude'],
          'is_mocked': gps['isMocked'],
          'public_ip': publicIp,
          'client_time': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Confirm QR Error: $e');
      return false;
    }
  }

  // ====== สัญญา (Installment Requests) ======
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
      return response.data;
    } catch (e) {
      print('Connection Error: $e');
      return [];
    }
  }

  // ====== Login ======
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
        print("TOKEN: ${response.data['token']}"); // DEBUG TOKEN
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // ====== Dashboard ======
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
      return response.data;
    } catch (e) {
      print('Dashboard error: $e');
      return null;
    }
  }

  // ====== ประวัติงวดผ่อน ======
  Future<List<dynamic>> getInstallmentPayments(int installmentRequestId) async {
    final token = await getToken();
    try {
      final response = await _dio.get(
        '/installment/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          'installment_request_id': installmentRequestId,
        },
      );
      return response.data['history'] ?? [];
    } catch (e) {
      print('Get Installment Payments Error: $e');
      return [];
    }
  }

  // ====== Profile ======
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    try {
      final response = await _dio.get('/user/profile',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // ====== Update Profile ======
  Future<bool> updateProfile(
    Map<String, dynamic> data, {
    File? idCardImage,
  }) async {
    final token = await getToken();
    FormData formData = FormData.fromMap({
      ...data,
      if (idCardImage != null)
        'id_card_image': await MultipartFile.fromFile(idCardImage.path),
    });

    try {
      final response = await _dio.post('/user/profile/update',
          data: formData,
          options: Options(headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          }));
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
