import 'dart:convert';

import 'package:flutter/material.dart';

class ReceiptViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final String? imageBase64;
  final String title;

  const ReceiptViewerScreen({
    super.key,
    this.imageUrl,
    this.imageBase64,
    this.title = 'Receipt',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(child: InteractiveViewer(child: _receiptImage())),
    );
  }

  Widget _receiptImage() {
    final base64Text = imageBase64;
    final url = imageUrl;

    if (base64Text != null && base64Text.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Text),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _errorText(),
        );
      } catch (_) {
        return _errorText();
      }
    }

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          final expectedBytes = loadingProgress.expectedTotalBytes;
          final loadedBytes = loadingProgress.cumulativeBytesLoaded;

          return CircularProgressIndicator(
            color: Colors.white,
            value: expectedBytes == null ? null : loadedBytes / expectedBytes,
          );
        },
        errorBuilder: (context, error, stackTrace) => _errorText(),
      );
    }

    return _errorText();
  }

  Widget _errorText() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Receipt image could not be loaded.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
