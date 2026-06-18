import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatefulWidget {
  final String adminId;
  final String billerId;
  final String billerName;

  const StatisticsScreen({
    super.key,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  String selectedFilter = 'All Time';

  Future<Map<String, dynamic>> _loadStatistics() async {
    final firestore = FirebaseFirestore.instance;

    final billsSnapshot = await firestore
        .collection('bills')
        .where('adminId', isEqualTo: widget.adminId)
        .where('billerId', isEqualTo: widget.billerId)
        .get();

    final paymentsSnapshot = await firestore
        .collection('payments')
        .where('adminId', isEqualTo: widget.adminId)
        .where('billerId', isEqualTo: widget.billerId)
        .get();

    int totalBillsAmount = 0;
    int totalPaidAmount = 0;
    int numberOfBills = 0;
    int numberOfPayments = 0;

    for (final doc in billsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? timestamp = data['createdAt'];

      if (_isInsideSelectedDate(timestamp)) {
        totalBillsAmount += _billAmount(data);
        numberOfBills++;
      }
    }

    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? timestamp = data['createdAt'];

      if (_isInsideSelectedDate(timestamp)) {
        totalPaidAmount += (data['paidAmount'] ?? 0) as int;
        numberOfPayments++;
      }
    }

    final ledgerQuery = await firestore
        .collection('ledgers')
        .where('adminId', isEqualTo: widget.adminId)
        .where('billerId', isEqualTo: widget.billerId)
        .limit(1)
        .get();

    int currentBalance = 0;

    if (ledgerQuery.docs.isNotEmpty) {
      currentBalance = (ledgerQuery.docs.first.data()['balance'] ?? 0) as int;
    }

    return {
      'totalBillsAmount': totalBillsAmount,
      'totalPaidAmount': totalPaidAmount,
      'numberOfBills': numberOfBills,
      'numberOfPayments': numberOfPayments,
      'currentBalance': currentBalance,
    };
  }

  bool _isInsideSelectedDate(Timestamp? timestamp) {
    if (fromDate == null || toDate == null) {
      return true;
    }

    if (timestamp == null) {
      return false;
    }

    final date = timestamp.toDate();

    return (date.isAtSameMomentAs(fromDate!) || date.isAfter(fromDate!)) &&
        (date.isAtSameMomentAs(toDate!) || date.isBefore(toDate!));
  }

  int _billAmount(Map<String, dynamic> bill) {
    final amount = bill['amount'] ?? bill['totalAmount'];
    if (amount is int) return amount;
    if (amount is num) return amount.toInt();
    return 0;
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();

    setState(() {
      selectedFilter = filter;

      if (filter == 'Today') {
        fromDate = DateTime(now.year, now.month, now.day);
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (filter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        fromDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (filter == 'This Month') {
        fromDate = DateTime(now.year, now.month, 1);
        toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        fromDate = null;
        toDate = null;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
    );

    if (picked == null) return;

    setState(() {
      selectedFilter = 'Custom';
      fromDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      toDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
    });
  }

  String _dateText() {
    if (fromDate == null || toDate == null) {
      return 'Showing: All Time';
    }

    final from = fromDate.toString().split(' ')[0];
    final to = toDate.toString().split(' ')[0];

    return 'Showing: $from to $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('${widget.billerName} Statistics'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip('All Time'),
                _filterChip('Today'),
                _filterChip('This Week'),
                _filterChip('This Month'),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Custom'),
                    selected: selectedFilter == 'Custom',
                    onSelected: (_) => _pickCustomDateRange(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _dateText(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadStatistics(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _statCard(
                      title: 'Total Bills Amount',
                      value: 'Rs ${stats['totalBillsAmount']}',
                      icon: Icons.receipt_long,
                      color: Colors.deepPurple,
                    ),
                    _statCard(
                      title: 'Total Paid Amount',
                      value: 'Rs ${stats['totalPaidAmount']}',
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                    _statCard(
                      title: 'Number Of Bills',
                      value: '${stats['numberOfBills']}',
                      icon: Icons.list_alt,
                      color: Colors.blue,
                    ),
                    _statCard(
                      title: 'Number Of Payments',
                      value: '${stats['numberOfPayments']}',
                      icon: Icons.payment,
                      color: Colors.orange,
                    ),
                    _statCard(
                      title: stats['currentBalance'] >= 0
                          ? 'Current Remaining'
                          : 'Current Advance',
                      value: 'Rs ${stats['currentBalance'].abs()}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == label,
        onSelected: (_) => _applyFilter(label),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
