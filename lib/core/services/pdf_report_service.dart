import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  final _db = FirebaseFirestore.instance;
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  Future<void> generateAdminBillerStatement({
    required String adminId,
    required String billerId,
    required String adminName,
    required String billerName,
  }) async {
    final ledgerQuery = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (ledgerQuery.docs.isEmpty) {
      throw Exception('Ledger not found for this biller.');
    }

    final ledger = ledgerQuery.docs.first.data();

    final billsQuery = await _db
        .collection('bills')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    final paymentsQuery = await _db
        .collection('payments')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    final bills = [...billsQuery.docs]..sort(_compareCreatedAt);
    final payments = [...paymentsQuery.docs]..sort(_compareCreatedAt);

    final totalBills = _asInt(ledger['totalBills']);
    final totalPaid = _asInt(ledger['totalPaid']);
    final balance = _asInt(ledger['balance']);
    final balanceLabel = balance >= 0 ? 'Remaining' : 'Advance';
    final generatedOn = _dateFormat.format(DateTime.now());

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _header(generatedOn),
            pw.SizedBox(height: 18),
            _sectionTitle('Account Info'),
            _infoTable([
              ['Admin', adminName],
              ['Biller', billerName],
            ]),
            pw.SizedBox(height: 18),
            _sectionTitle('Ledger Summary'),
            _infoTable([
              ['Total Bills', 'Rs $totalBills'],
              ['Total Paid', 'Rs $totalPaid'],
              [balanceLabel, 'Rs ${balance.abs()}'],
            ]),
            pw.SizedBox(height: 18),
            _sectionTitle('Bills History'),
            bills.isEmpty ? _emptyText('No bills found') : _billsTable(bills),
            pw.SizedBox(height: 18),
            _sectionTitle('Payment History'),
            payments.isEmpty
                ? _emptyText('No payments found')
                : _paymentsTable(payments),
            pw.SizedBox(height: 18),
            _sectionTitle('Final Status'),
            _infoTable([
              ['Current $balanceLabel', 'Rs ${balance.abs()}'],
            ]),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: '${billerName}_statement.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _header(String generatedOn) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Family Billing App',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Admin-Biller Statement',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Generated On: $generatedOn'),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: PdfColors.deepPurple100,
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _infoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [_cell(row[0], isHeader: true), _cell(row[1])],
        );
      }).toList(),
    );
  }

  pw.Widget _billsTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('Date', isHeader: true),
            _cell('Bill Title', isHeader: true),
            _cell('Amount', isHeader: true),
          ],
        ),
        ...docs.map((doc) {
          final bill = doc.data();
          return pw.TableRow(
            children: [
              _cell(_formatTimestamp(bill['createdAt'])),
              _cell((bill['title'] ?? 'Untitled Bill').toString()),
              _cell('Rs ${_asInt(bill['totalAmount'])}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _paymentsTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('Date', isHeader: true),
            _cell('Paid Amount', isHeader: true),
            _cell('Balance After Payment', isHeader: true),
          ],
        ),
        ...docs.map((doc) {
          final payment = doc.data();
          final balanceAfter = _asInt(payment['balanceAfter']);
          return pw.TableRow(
            children: [
              _cell(_formatTimestamp(payment['createdAt'])),
              _cell('Rs ${_asInt(payment['paidAmount'])}'),
              _cell('Rs ${balanceAfter.abs()}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _emptyText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy').format(value.toDate());
    }

    return 'N/A';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  int _compareCreatedAt(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aTime = a.data()['createdAt'];
    final bTime = b.data()['createdAt'];

    if (aTime is Timestamp && bTime is Timestamp) {
      return aTime.compareTo(bTime);
    }

    if (aTime is Timestamp) return -1;
    if (bTime is Timestamp) return 1;
    return 0;
  }
}
