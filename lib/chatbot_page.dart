import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:finsage/services/finance_expert_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final FinanceExpertService _expertService = FinanceExpertService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "text":
          "Hey! I'm **Bodhi**. I've looked at your recent data. Want me to analyze your spending or give you some saving tips? 💰",
      "isUser": false,
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? quickText]) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _expertService.askExpert(text);
      setState(() {
        _messages.add({"text": response, "isUser": false});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "text": "Expert Error: Please check your API key and connection.",
          "isUser": false,
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  // ✨ IMPROVED: Glassmorphism Quick Action Button
  Widget _quickAction(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => _sendMessage(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), // Very subtle glass effect
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ), // Thin border
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mascot Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white10,
                backgroundImage: AssetImage('assets/bodhi/casual.png'),
              ),
              const SizedBox(width: 12),
              const Text(
                "Bodhi AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, color: Colors.white38, size: 20),
            ],
          ),
        ),

        // Chat History
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _ChatBubble(text: msg['text'], isUser: msg['isUser']);
            },
          ),
        ),

        // Input & Quick Actions
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                color: Color(0xFFB76E79),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Actions Row (Now Blended)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _quickAction("Analyze spending"),
                      _quickAction("Saving tips"),
                      _quickAction("Budget status"),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Modern Rounded Input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Talk to Bodhi...",
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _sendMessage(),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFB76E79), // Rose Gold
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage('assets/bodhi/casual.png'),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFB76E79)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
