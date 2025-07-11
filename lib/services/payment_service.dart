import 'dart:convert';
import 'package:dio/dio.dart';

class PaymentService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<Map<String, dynamic>?> createQrPayment({
    required String amount,
    int qrType = 3,
    String? partnerTxnUid,
  }) async {
    try {
      final response = await Dio().post(
        '$baseUrl/payment/qr',
        data: {
          'amount': amount,
          'qrType': qrType,
          if (partnerTxnUid != null) 'partnerTxnUid': partnerTxnUid,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data;
    } catch (e) {
      print('Error createQrPayment: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQrStatus(String qrRef) async {
    try {
      final response = await Dio().get('$baseUrl/payment/qr-status/$qrRef');
      return response.data;
    } catch (e) {
      print('Error getQrStatus: $e');
      return null;
    }
  }
}
