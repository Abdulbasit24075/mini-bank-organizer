class Bill {
  final String id;
  final String title;
  final int totalAmount;
  final int paidAmount;
  final String billerId;
  final String adminId;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.paidAmount,
    required this.billerId,
    required this.adminId,
    required this.createdAt,
  });

  int get remainingAmount => totalAmount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'billerId': billerId,
      'adminId': adminId,
      'createdAt': createdAt,
    };
  }
}
