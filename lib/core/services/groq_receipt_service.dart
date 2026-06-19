import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GroqReceiptResult {
  final String title;
  final String billDetails;
  final int totalAmount;
  final String rawResponse;

  const GroqReceiptResult({
    required this.title,
    required this.billDetails,
    required this.totalAmount,
    required this.rawResponse,
  });
}

class GroqReceiptService {
  static const String _groqApiKey = 'PASTE_GROQ_KEY_HERE';
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  Future<GroqReceiptResult> extractReceipt(File imageFile) async {
    if (_groqApiKey == 'PASTE_GROQ_KEY_HERE' || _groqApiKey.trim().isEmpty) {
      throw Exception('Please paste your Groq API key first.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final dataUrl = 'data:image/jpeg;base64,$imageBase64';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': _receiptPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
          },
        ],
        'temperature': 0,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Groq receipt extraction failed (${response.statusCode}). ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'];

    if (choices is! List || choices.isEmpty) {
      throw Exception('Groq did not return a receipt result.');
    }

    final message = choices.first['message'];
    final rawContent = message is Map<String, dynamic>
        ? (message['content'] ?? '').toString()
        : '';

    if (rawContent.trim().isEmpty) {
      throw Exception('Groq returned an empty receipt result.');
    }

    return _parseReceiptResult(rawContent);
  }

  GroqReceiptResult _parseReceiptResult(String rawResponse) {
    final jsonText = _extractJsonText(rawResponse);

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not read receipt JSON from Groq response.');
    }

    final title = (data['title'] ?? '').toString().trim();
    final billDetails = (data['billDetails'] ?? '').toString().trim();
    final totalAmount = _asInt(data['totalAmount']);

    if (title.isEmpty) {
      throw Exception('Groq could not find a bill title.');
    }

    if (billDetails.isEmpty) {
      throw Exception('Groq could not find bill details.');
    }

    if (totalAmount <= 0) {
      throw Exception('Groq could not find a valid total amount.');
    }

    return GroqReceiptResult(
      title: title,
      billDetails: billDetails,
      totalAmount: totalAmount,
      rawResponse: rawResponse,
    );
  }

  String _extractJsonText(String rawResponse) {
    var text = rawResponse.trim();

    text = text
        .replaceAll(RegExp(r'^```json', caseSensitive: false), '')
        .replaceAll(RegExp(r'^```', caseSensitive: false), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start == -1 || end == -1 || end <= start) {
      throw Exception('Groq response did not contain valid JSON.');
    }

    return text.substring(start, end + 1);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final cleaned = value?.toString().replaceAll(RegExp(r'[^0-9.]'), '').trim();

    if (cleaned == null || cleaned.isEmpty) return 0;

    return double.tryParse(cleaned)?.round() ?? 0;
  }
}

const String _receiptPrompt = '''
Read this receipt image and extract bill data.

Return JSON only in this exact format:
{
  "title": "",
  "billDetails": "",
  "totalAmount": 0
}

Rules:
- title should be short and meaningful.
- billDetails should contain item lines like "Item - price".
- totalAmount must be the final/net/paid total.
- If multiple items exist, put each item on a new line using \\n.
- Do not include markdown.
- Do not include explanation.
- Do not include currency symbols in totalAmount.
- totalAmount must be integer.
''';
