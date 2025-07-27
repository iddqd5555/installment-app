class InstallmentPayment {
  final int id;
  final int installmentRequestId;
  final double amount;
  double? amountPaid;
  String paymentStatus;
  String status;
  String? paymentProof;
  String? slipHash;
  DateTime paymentDueDate;

  InstallmentPayment({
    required this.id,
    required this.installmentRequestId,
    required this.amount,
    this.amountPaid,
    required this.paymentStatus,
    required this.status,
    this.paymentProof,
    this.slipHash,
    required this.paymentDueDate,
  });

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) {
    // amount, amount_paid, installment_request_id อาจเป็น String หรือ null
    double _parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return InstallmentPayment(
      id: json['id'] ?? 0,
      installmentRequestId: json['installment_request_id'] ?? 0,
      amount: _parseDouble(json['amount']),
      amountPaid: json.containsKey('amount_paid') ? _parseDouble(json['amount_paid']) : null,
      paymentStatus: json['payment_status'] ?? 'pending',
      status: json['status'] ?? 'pending',
      paymentProof: json['payment_proof'],
      slipHash: json['slip_hash'],
      paymentDueDate: DateTime.parse(json['payment_due_date']),
    );
  }
}
