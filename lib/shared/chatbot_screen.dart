import 'package:flutter/material.dart';
import '../core/services/local_chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  final String role;
  final String? adminId;
  final String? billerId;

  const ChatbotScreen({
    super.key,
    required this.role,
    this.adminId,
    this.billerId,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final LocalChatbotService _chatbotService = LocalChatbotService();

  bool isLoading = false;

  final List<Map<String, String>> messages = [
    {
      'sender': 'bot',
      'text':
          'Hello! I can help you with bills, receipts, ledger, payments, history, price checker, and app usage. Use @ before app-help questions, like @ how to create bill.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> sendMessage() async {
    final text = _messageCtrl.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': text});
      _messageCtrl.clear();
      isLoading = true;
    });

    final reply = await _chatbotService.ask(
      question: text,
      role: widget.role,
      adminId: widget.adminId,
      billerId: widget.billerId,
    );

    setState(() {
      messages.add({'sender': 'bot', 'text': reply});
      isLoading = false;
    });
  }

  Widget messageBubble(Map<String, String> msg) {
    final isUser = msg['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Smart Assistant'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return messageBubble(messages[index]);
              },
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Ask something... use @ for app help',
                      suffixIcon: _messageCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _messageCtrl.clear();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: isLoading ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
