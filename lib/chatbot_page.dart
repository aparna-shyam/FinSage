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
          "Hey! I'm **Bodhi**, your FinSage guide. Ask me anything about your spending! 💰",
      "isUser": false,
    });
  }

  // Improved scroll logic to ensure it hits the absolute bottom
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    // Prevent sending if already loading (helps avoid 429 errors)
    if (_isLoading) return;

    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Call the service
    final response = await _expertService.askExpert(text);

    if (mounted) {
      setState(() {
        _messages.add({"text": response, "isUser": false});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add({
        "text": "Chat cleared! How can Bodhi help you now?",
        "isUser": false,
      });
    });
  }

  Widget _quickAction(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: _isLoading
            ? null
            : () => _sendMessage(label), // Disable if loading
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isLoading ? Colors.white10 : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _isLoading ? Colors.white24 : Colors.white70,
              fontSize: 13,
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
        // Header with Clear Chat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
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
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.white38,
                ),
                onPressed: _isLoading ? null : _clearChat,
              ),
            ],
          ),
        ),

        // Chat List
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

        // Animated Loading Indicator
        if (_isLoading)
          const LinearProgressIndicator(
            color: Color(0xFFB76E79),
            backgroundColor: Colors.transparent,
            minHeight: 2,
          ),

        // Input & Quick Actions
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _quickAction("Analyze spending"),
                      _quickAction("Saving tips"),
                      _quickAction("Budget status"),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: !_isLoading, // Disable typing while loading
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
                    const SizedBox(width: 8),
                    // Send Button with Loading logic
                    GestureDetector(
                      onTap: _isLoading ? null : () => _sendMessage(),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: _isLoading
                            ? Colors.white10
                            : const Color(0xFFB76E79),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white38,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
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
              backgroundColor: Colors.white10,
              backgroundImage: AssetImage('assets/bodhi/casual.png'),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
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
                  p: const TextStyle(color: Colors.white, height: 1.4),
                  code: TextStyle(
                    backgroundColor: Colors.white10,
                    color: Colors.amber[100],
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
