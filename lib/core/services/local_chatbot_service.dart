import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatBotReply {
  final String answer;
  final double score;

  ChatBotReply({required this.answer, required this.score});
}

class _FaqEntry {
  final List<String> patterns;
  final String answer;

  const _FaqEntry({required this.patterns, required this.answer});
}

class _FirestoreIntent {
  final String name;
  final List<String> patterns;

  const _FirestoreIntent({required this.name, required this.patterns});
}

class LedgerStats {
  final int totalBills;
  final int totalPaid;
  final int balance;

  const LedgerStats({
    required this.totalBills,
    required this.totalPaid,
    required this.balance,
  });
}

class BillStats {
  final int count;
  final int totalAmount;
  final int receiptCount;

  const BillStats({
    required this.count,
    required this.totalAmount,
    required this.receiptCount,
  });
}

class PaymentStats {
  final int count;
  final int totalPaid;

  const PaymentStats({required this.count, required this.totalPaid});
}

class LocalChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Set<String> _importantKeywords = {
    'bill',
    'bills',
    'receipt',
    'ledger',
    'balance',
    'remaining',
    'advance',
    'payment',
    'payments',
    'paid',
    'admin',
    'biller',
    'linked',
    'notebook',
    'statistics',
    'pdf',
    'price',
    'details',
    'amount',
    'total',
    'history',
    'data',
  };

  final List<_FaqEntry> _faqList = const [
    _FaqEntry(
      patterns: [
        'how to create bill',
        'how i make bill',
        'make new bill',
        'create manual bill',
        'add bill',
        'new bill entry',
        'biller create bill',
      ],
      answer:
          'To create a bill, open Biller Dashboard, tap Create Bill, enter bill title, bill details, total amount, pick receipt image, then press Create Bill.',
    ),
    _FaqEntry(
      patterns: [
        'how to add bill details',
        'what is bill details',
        'where write bill items',
        'multiple item bill',
        'bill item details',
        'write sugar rice flour',
      ],
      answer:
          'Bill Details is a multiline text field. Write items there, for example: Sugar - 500, Rice - 1200, Flour - 900. This text is only descriptive.',
    ),
    _FaqEntry(
      patterns: [
        'how to upload receipt image',
        'where add receipt',
        'pick receipt',
        'add receipt photo',
        'upload bill proof',
        'receipt image',
      ],
      answer:
          'When creating a bill, tap Pick Receipt Image, select the receipt from gallery, preview it, then create the bill. The receipt is saved as proof.',
    ),
    _FaqEntry(
      patterns: [
        'how to view receipt',
        'open receipt image',
        'see bill proof',
        'view receipt button',
        'where receipt show',
      ],
      answer:
          'Open bill history. If a bill has a receipt, tap View Receipt. The receipt will open in full screen.',
    ),
    _FaqEntry(
      patterns: [
        'how bill history works',
        'where see bills',
        'show old bills',
        'bill history',
        'created bills list',
      ],
      answer:
          'Bill History shows created bills with title, bill details, amount, date/time, and View Receipt button when a receipt is attached.',
    ),
    _FaqEntry(
      patterns: [
        'how ledger works',
        'what is ledger',
        'ledger balance',
        'remaining advance logic',
        'how balance calculated',
      ],
      answer:
          'Ledger uses total bill amount and paid amount. Bills increase remaining balance. Payments reduce remaining balance or create advance.',
    ),
    _FaqEntry(
      patterns: [
        'how payment works',
        'how admin pay',
        'pay combined amount',
        'payment history',
        'admin payment',
      ],
      answer:
          'Admin opens a biller ledger, enters payment amount, and submits payment. The paid amount updates ledger totals and creates payment history.',
    ),
    _FaqEntry(
      patterns: [
        'how admin adds biller',
        'add biller',
        'link biller',
        'admin add user',
        'connect biller with admin',
      ],
      answer:
          'Admin opens dashboard, taps the add user button, selects biller, and links a biller account. One biller should be linked to one admin only.',
    ),
    _FaqEntry(
      patterns: [
        'how linked users work',
        'linked users',
        'my linked biller',
        'my linked admin',
        'admin biller relation',
      ],
      answer:
          'Linked users connect one admin with billers. Admin can view linked billers, and biller can see the assigned admin on the dashboard.',
    ),
    _FaqEntry(
      patterns: [
        'how notebooks work',
        'notebook summary',
        'save note',
        'save ledger summary',
        'edit notebook',
        'delete notebook',
      ],
      answer:
          'Notebook lets admin or biller save ledger snapshots with month detail and comments. Notebook records can be edited or deleted.',
    ),
    _FaqEntry(
      patterns: [
        'how price checker works',
        'price checker',
        'check product price',
        'market price',
        'city product price',
      ],
      answer:
          'Price Checker helps admin check estimated market prices using city and product information. It is for manual verification, not automatic bill approval.',
    ),
    _FaqEntry(
      patterns: [
        'how statistics work',
        'statistics screen',
        'view stats',
        'bill payment stats',
        'date filter statistics',
      ],
      answer:
          'Statistics shows total bills amount, total paid amount, number of bills, number of payments, and current remaining or advance balance.',
    ),
    _FaqEntry(
      patterns: [
        'how pdf reports work',
        'export pdf',
        'pdf statement',
        'download report',
        'admin biller statement',
      ],
      answer:
          'Admin can export a PDF statement from a selected biller ledger. It includes account info, ledger summary, transaction history, and final status.',
    ),
    _FaqEntry(
      patterns: [
        'how manual bill works',
        'manual bill',
        'manual bill creation',
        'bill without ai',
        'single bill document',
      ],
      answer:
          'Manual bill creation stores one bill as one Firestore document. Title, billDetails, amount, receipt proof, createdMethod, adminId, and billerId are saved together.',
    ),
    _FaqEntry(
      patterns: [
        'how total amount affects ledger',
        'amount affect ledger',
        'total amount ledger',
        'ledger use amount',
        'which field update ledger',
      ],
      answer:
          'Only the total amount field affects ledger calculations. For example, if total amount is 2600, ledger increases by 2600.',
    ),
    _FaqEntry(
      patterns: [
        'does receipt image affect ledger',
        'receipt affect balance',
        'receipt change ledger',
        'receipt proof ledger',
      ],
      answer:
          'No. Receipt image is only proof. It does not affect ledger, remaining balance, advance amount, or payment history.',
    ),
    _FaqEntry(
      patterns: [
        'does bill details affect ledger',
        'bill details affect balance',
        'items affect ledger',
        'details change amount',
      ],
      answer:
          'No. Bill details are informational only. Ledger updates only from the total amount field.',
    ),
  ];

  final List<_FirestoreIntent> _firestoreIntents = const [
    _FirestoreIntent(
      name: 'balance',
      patterns: [
        'my balance',
        'current balance',
        'remaining amount',
        'advance amount',
        'how much remaining',
        'how much advance',
        'ledger balance',
        'biller remaining amount',
      ],
    ),
    _FirestoreIntent(
      name: 'totalBillsAmount',
      patterns: [
        'total bills',
        'total bill amount',
        'how much bills',
        'bills total',
        'total expense',
        'total spending',
      ],
    ),
    _FirestoreIntent(
      name: 'numberOfBills',
      patterns: [
        'how many bills',
        'number of bills',
        'bill count',
        'total bill entries',
      ],
    ),
    _FirestoreIntent(
      name: 'totalPaid',
      patterns: [
        'total paid',
        'payment total',
        'how much paid',
        'paid amount',
        'payments amount',
        'admin payment total',
      ],
    ),
    _FirestoreIntent(
      name: 'numberOfPayments',
      patterns: [
        'how many payments',
        'payment count',
        'number of payments',
        'total payment entries',
      ],
    ),
    _FirestoreIntent(
      name: 'linkedUser',
      patterns: [
        'my linked biller',
        'my linked admin',
        'who is my admin',
        'who is my biller',
        'linked users',
        'show my linked biller data',
      ],
    ),
    _FirestoreIntent(
      name: 'receiptBills',
      patterns: [
        'how many bills have receipt',
        'bills with receipt',
        'receipt uploaded bills',
        'receipt bills',
        'bills proof image',
      ],
    ),
    _FirestoreIntent(
      name: 'billHistory',
      patterns: [
        'biller history',
        'bill history with biller',
        'give me biller history',
        'show biller history',
        'history with biller',
        'show my linked biller data',
        'biller bills data',
      ],
    ),
  ];

  Future<String> ask({
    required String question,
    required String role,
    String? adminId,
    String? billerId,
  }) async {
    final trimmedQuestion = question.trim();
    final helpOnlyMode = trimmedQuestion.startsWith('@');
    final normalizedQuestion = normalizeText(
      helpOnlyMode ? trimmedQuestion.substring(1) : trimmedQuestion,
    );

    if (normalizedQuestion.isEmpty) {
      return 'Please type a question. Use @ before app-help questions, for example: @ how to create bill.';
    }

    if (helpOnlyMode) {
      final faqAnswer = findBestFaqAnswer(normalizedQuestion);

      if (faqAnswer.score < 0.22) {
        return 'I am a local app assistant. With @, I can answer app-help questions about bills, receipts, ledger, payments, price checker, statistics, notebooks, PDF reports, or linked users.';
      }

      return _answerWithRoleScreenHint(
        answer: faqAnswer.answer,
        question: normalizedQuestion,
        role: normalizeText(role),
      );
    }

    final firestoreAnswer = await _tryFirestoreAnswer(
      question: normalizedQuestion,
      role: normalizeText(role),
      adminId: adminId,
      billerId: billerId,
    );

    if (firestoreAnswer != null) return firestoreAnswer;

    final faqAnswer = findBestFaqAnswer(normalizedQuestion);

    if (faqAnswer.score < 0.22) {
      return 'Sorry, I could not understand. You can ask about bills, receipts, ledger, payments, price checker, statistics, notebooks, or linked users. For app-help guidance only, start your question with @, for example: @ how to upload receipt.';
    }

    return _answerWithRoleScreenHint(
      answer: faqAnswer.answer,
      question: normalizedQuestion,
      role: normalizeText(role),
    );
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> tokenize(String text) {
    final normalized = normalizeText(text);
    if (normalized.isEmpty) return [];

    return normalized
        .split(' ')
        .where((word) => word.trim().length > 1)
        .toList();
  }

  double similarity(String a, String b) {
    final wordsA = tokenize(a);
    final wordsB = tokenize(b);

    if (wordsA.isEmpty || wordsB.isEmpty) return 0;

    double score = 0;
    final matchedB = <int>{};

    for (final wordA in wordsA) {
      double bestWordScore = 0;
      int bestIndex = -1;

      for (int i = 0; i < wordsB.length; i++) {
        if (matchedB.contains(i)) continue;

        final wordB = wordsB[i];
        final currentScore = _wordSimilarity(wordA, wordB);

        if (currentScore > bestWordScore) {
          bestWordScore = currentScore;
          bestIndex = i;
        }
      }

      if (bestWordScore >= 0.58) {
        matchedB.add(bestIndex);
        score += bestWordScore;

        if (_importantKeywords.contains(wordA) ||
            _importantKeywords.contains(wordsB[bestIndex])) {
          score += 0.45;
        }
      }
    }

    final unionSize = {...wordsA, ...wordsB}.length;
    final lengthBalance = wordsA.length < wordsB.length
        ? wordsA.length / wordsB.length
        : 1.0;

    return (score / unionSize) + (lengthBalance * 0.08);
  }

  int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      current[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        final insertCost = current[j] + 1;
        final deleteCost = previous[j + 1] + 1;
        final replaceCost = previous[j] + (a[i] == b[j] ? 0 : 1);

        current[j + 1] = [
          insertCost,
          deleteCost,
          replaceCost,
        ].reduce((value, element) => value < element ? value : element);
      }

      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  ChatBotReply findBestFaqAnswer(String question) {
    double bestScore = 0;
    String bestAnswer = '';

    for (final item in _faqList) {
      for (final pattern in item.patterns) {
        final score = similarity(question, pattern);

        if (score > bestScore) {
          bestScore = score;
          bestAnswer = item.answer;
        }
      }
    }

    return ChatBotReply(answer: bestAnswer, score: bestScore);
  }

  ChatBotReply findBestFirestoreIntent(String question) {
    double bestScore = 0;
    String bestIntent = '';

    for (final intent in _firestoreIntents) {
      for (final pattern in intent.patterns) {
        final score = similarity(question, pattern);

        if (score > bestScore) {
          bestScore = score;
          bestIntent = intent.name;
        }
      }
    }

    return ChatBotReply(answer: bestIntent, score: bestScore);
  }

  Future<LedgerStats?> loadLedgerStats({
    required String adminId,
    required String billerId,
  }) async {
    final ledgerQuery = await _firestore
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (ledgerQuery.docs.isEmpty) return null;

    final data = ledgerQuery.docs.first.data();

    return LedgerStats(
      totalBills: _asInt(data['totalBills']),
      totalPaid: _asInt(data['totalPaid']),
      balance: _asInt(data['balance']),
    );
  }

  Future<BillStats> loadBillStats({
    required String adminId,
    required String billerId,
  }) async {
    final billsQuery = await _firestore
        .collection('bills')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    int totalAmount = 0;
    int receiptCount = 0;

    for (final doc in billsQuery.docs) {
      final data = doc.data();
      totalAmount += _asInt(data['amount'] ?? data['totalAmount']);

      final receiptImageUrl = (data['receiptImageUrl'] ?? '').toString();
      final receiptImageBase64 = (data['receiptImageBase64'] ?? '').toString();

      if (receiptImageUrl.trim().isNotEmpty ||
          receiptImageBase64.trim().isNotEmpty) {
        receiptCount++;
      }
    }

    return BillStats(
      count: billsQuery.docs.length,
      totalAmount: totalAmount,
      receiptCount: receiptCount,
    );
  }

  Future<PaymentStats> loadPaymentStats({
    required String adminId,
    required String billerId,
  }) async {
    final paymentsQuery = await _firestore
        .collection('payments')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    int totalPaid = 0;

    for (final doc in paymentsQuery.docs) {
      final data = doc.data();
      totalPaid += _asInt(data['paidAmount']);
    }

    return PaymentStats(count: paymentsQuery.docs.length, totalPaid: totalPaid);
  }

  Future<Map<String, dynamic>?> findLinkedAdminForBiller(
    String billerId,
  ) async {
    final relationQuery = await _firestore
        .collection('relationships')
        .where('linkedUserId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (relationQuery.docs.isEmpty) return null;

    final adminId = relationQuery.docs.first.data()['createdBy'];
    if (adminId == null) return null;

    final adminDoc = await _firestore.collection('users').doc(adminId).get();
    final adminData = adminDoc.data();

    if (adminData == null) return null;

    return {...adminData, 'uid': adminDoc.id};
  }

  Future<String?> _tryFirestoreAnswer({
    required String question,
    required String role,
    String? adminId,
    String? billerId,
  }) async {
    final bestIntent = findBestFirestoreIntent(question);
    if (bestIntent.score < 0.28) return null;

    final resolvedPair = await _resolveAdminBillerPair(
      role: role,
      adminId: adminId,
      billerId: billerId,
      question: question,
      intentName: bestIntent.answer,
    );

    if (bestIntent.answer == 'linkedUser') {
      return _linkedUserAnswer(
        role: role,
        adminId: adminId,
        billerId: billerId,
      );
    }

    if (resolvedPair == null) {
      if (role == 'admin' && billerId == null) {
        return 'Open a specific biller ledger/history to ask about that biller data.';
      }

      if (role == 'biller' && adminId == null) {
        return 'I could not find your linked admin yet. Please make sure an admin has linked your biller account.';
      }

      return 'I need a specific admin-biller relationship to answer this data question.';
    }

    final resolvedAdminId = resolvedPair['adminId']!;
    final resolvedBillerId = resolvedPair['billerId']!;

    switch (bestIntent.answer) {
      case 'balance':
        final ledger = await loadLedgerStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );

        if (ledger == null) {
          return 'No ledger found for this admin-biller relationship yet.';
        }

        if (ledger.balance >= 0) {
          return 'Current remaining balance is Rs. ${ledger.balance}.';
        }

        return 'Current advance amount is Rs. ${ledger.balance.abs()}.';

      case 'totalBillsAmount':
        final bills = await loadBillStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
        return 'Total bills amount is Rs. ${bills.totalAmount}.';

      case 'numberOfBills':
        final bills = await loadBillStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
        return 'There are ${bills.count} bills for this admin-biller relationship.';

      case 'totalPaid':
        final payments = await loadPaymentStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
        return 'Total paid amount is Rs. ${payments.totalPaid}.';

      case 'numberOfPayments':
        final payments = await loadPaymentStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
        return 'There are ${payments.count} payments for this admin-biller relationship.';

      case 'receiptBills':
        final bills = await loadBillStats(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
        return '${bills.receiptCount} bills have receipt images attached.';

      case 'billHistory':
        return _billHistoryAnswer(
          adminId: resolvedAdminId,
          billerId: resolvedBillerId,
        );
    }

    return null;
  }

  Future<Map<String, String>?> _resolveAdminBillerPair({
    required String role,
    required String? adminId,
    required String? billerId,
    required String question,
    required String intentName,
  }) async {
    if (adminId != null && billerId != null) {
      return {'adminId': adminId, 'billerId': billerId};
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final effectiveAdminId =
        adminId ?? (role == 'admin' ? currentUserId : null);
    final effectiveBillerId =
        billerId ?? (role == 'biller' ? currentUserId : null);

    if (role == 'admin' && effectiveAdminId != null && billerId == null) {
      final linkedBiller = await _findLinkedBillerFromQuestion(
        adminId: effectiveAdminId,
        question: question,
      );

      if (linkedBiller != null) {
        return {
          'adminId': effectiveAdminId,
          'billerId': linkedBiller['uid']!.toString(),
        };
      }
    }

    if (role == 'biller' && effectiveBillerId != null && adminId == null) {
      final admin = await findLinkedAdminForBiller(effectiveBillerId);
      final resolvedAdminId = admin?['uid']?.toString();

      if (resolvedAdminId == null || resolvedAdminId.isEmpty) return null;

      return {'adminId': resolvedAdminId, 'billerId': effectiveBillerId};
    }

    return null;
  }

  Future<String> _linkedUserAnswer({
    required String role,
    required String? adminId,
    required String? billerId,
  }) async {
    if (role == 'biller' && billerId != null) {
      final admin = await findLinkedAdminForBiller(billerId);

      if (admin == null) {
        return 'No linked admin found for this biller account yet.';
      }

      final name = (admin['name'] ?? 'Admin').toString();
      final email = (admin['email'] ?? '').toString();

      if (email.isEmpty) {
        return 'Your linked admin is $name.';
      }

      return 'Your linked admin is $name ($email).';
    }

    final effectiveAdminId =
        adminId ??
        (role == 'admin' ? FirebaseAuth.instance.currentUser?.uid : null);

    if (role == 'admin' && effectiveAdminId != null) {
      final relationQuery = await _firestore
          .collection('relationships')
          .where('createdBy', isEqualTo: effectiveAdminId)
          .get();

      if (relationQuery.docs.isEmpty) {
        return 'No linked billers found for this admin account yet.';
      }

      return 'You have ${relationQuery.docs.length} linked biller(s). Open a specific biller ledger/history to ask about that biller data.';
    }

    return 'Open your dashboard or a specific biller ledger/history to view linked user data.';
  }

  double _wordSimilarity(String a, String b) {
    if (a == b) return 1.0;

    if (a.length > 2 && b.length > 2 && (a.contains(b) || b.contains(a))) {
      return 0.82;
    }

    final distance = levenshtein(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;

    if (maxLength == 0) return 0;

    final score = 1 - (distance / maxLength);
    return score < 0 ? 0 : score;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Future<Map<String, String>?> _findLinkedBillerFromQuestion({
    required String adminId,
    required String question,
  }) async {
    final relationQuery = await _firestore
        .collection('relationships')
        .where('createdBy', isEqualTo: adminId)
        .get();

    if (relationQuery.docs.isEmpty) return null;

    Map<String, String>? bestBiller;
    double bestScore = 0;

    for (final relation in relationQuery.docs) {
      final linkedUserId = relation.data()['linkedUserId']?.toString();
      if (linkedUserId == null || linkedUserId.isEmpty) continue;

      final userDoc = await _firestore
          .collection('users')
          .doc(linkedUserId)
          .get();
      final userData = userDoc.data();
      if (userData == null) continue;

      final name = (userData['name'] ?? '').toString();
      final email = (userData['email'] ?? '').toString();
      final role = (userData['role'] ?? '').toString();

      if (role.isNotEmpty && normalizeText(role) != 'biller') continue;

      final score = [
        similarity(question, name),
        similarity(question, email),
        similarity(question, '$name $email'),
      ].reduce((value, element) => value > element ? value : element);

      if (score > bestScore) {
        bestScore = score;
        bestBiller = {
          'uid': userDoc.id,
          'name': name.isEmpty ? 'Biller' : name,
          'email': email,
        };
      }
    }

    if (bestScore < 0.20) return null;
    return bestBiller;
  }

  Future<String> _billHistoryAnswer({
    required String adminId,
    required String billerId,
  }) async {
    final billerDoc = await _firestore.collection('users').doc(billerId).get();
    final billerName = (billerDoc.data()?['name'] ?? 'this biller').toString();

    final billsQuery = await _firestore
        .collection('bills')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    if (billsQuery.docs.isEmpty) {
      return 'No bill history found for $billerName yet.';
    }

    final docs = [...billsQuery.docs]
      ..sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        if (aTime is Timestamp) return -1;
        if (bTime is Timestamp) return 1;
        return 0;
      });

    int totalAmount = 0;
    final recentLines = <String>[];

    for (final doc in docs) {
      final data = doc.data();
      totalAmount += _asInt(data['amount'] ?? data['totalAmount']);

      if (recentLines.length < 5) {
        final title = (data['title'] ?? 'Untitled Bill').toString();
        final amount = _asInt(data['amount'] ?? data['totalAmount']);
        recentLines.add('- $title: Rs. $amount');
      }
    }

    return 'Bill history for $billerName: ${docs.length} bill(s), total amount Rs. $totalAmount.\nRecent bills:\n${recentLines.join('\n')}';
  }

  String _answerWithRoleScreenHint({
    required String answer,
    required String question,
    required String role,
  }) {
    final screenHint = _screenHintForQuestion(question: question, role: role);
    if (screenHint == null) return answer;
    return '$answer\n\nScreen path: $screenHint';
  }

  String? _screenHintForQuestion({
    required String question,
    required String role,
  }) {
    final q = normalizeText(question);

    if (_matchesAny(q, ['create bill', 'make bill', 'add bill'])) {
      return role == 'biller'
          ? 'Biller Dashboard -> Create Bill'
          : 'Admin cannot create bills. Ask the biller to open Biller Dashboard -> Create Bill.';
    }

    if (_matchesAny(q, ['receipt', 'bill proof'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller -> View Bill History -> View Receipt'
          : 'Biller Dashboard -> Bill History -> View Receipt';
    }

    if (_matchesAny(q, ['bill history', 'old bills', 'created bills'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller -> View Bill History'
          : 'Biller Dashboard -> Bill History';
    }

    if (_matchesAny(q, ['ledger', 'balance', 'remaining', 'advance'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller ledger'
          : 'Biller Dashboard -> My Account';
    }

    if (_matchesAny(q, ['payment', 'paid'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller -> Pay Combined Amount'
          : 'Biller Dashboard -> Payment History';
    }

    if (_matchesAny(q, ['statistics', 'stats'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller -> View Statistics'
          : 'Biller Dashboard -> Statistics';
    }

    if (_matchesAny(q, ['notebook', 'note', 'summary'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> Notebooks'
          : 'Biller Dashboard -> Notebook';
    }

    if (_matchesAny(q, ['price checker', 'price', 'market'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> Price Checker'
          : 'Price Checker is available from Admin Dashboard.';
    }

    if (_matchesAny(q, ['pdf', 'report', 'statement'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers -> select biller -> Export PDF'
          : 'PDF export is available for admin from a selected biller ledger.';
    }

    if (_matchesAny(q, ['linked', 'admin', 'biller'])) {
      return role == 'admin'
          ? 'Admin Dashboard -> My Billers'
          : 'Biller Dashboard -> My Admin';
    }

    return null;
  }

  bool _matchesAny(String question, List<String> patterns) {
    for (final pattern in patterns) {
      if (similarity(question, pattern) >= 0.28) return true;
    }

    return false;
  }
}
