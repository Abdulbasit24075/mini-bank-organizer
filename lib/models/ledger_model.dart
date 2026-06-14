class Ledger {
  final String adminId;
  final String billerId;
  final int totalBills;
  final int totalPaid;
  final int balance; // totalBills - totalPaid (negative = advance)

  Ledger({
    required this.adminId,
    required this.billerId,
    required this.totalBills,
    required this.totalPaid,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'billerId': billerId,
      'totalBills': totalBills,
      'totalPaid': totalPaid,
      'balance': balance,
      'updatedAt': DateTime.now(),
    };
  }
}
