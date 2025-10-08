import 'package:flutter/material.dart';
import '../services/voice_input_service.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final String? hint;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.hint,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);

    final result = await _voiceService.startListening();

    setState(() => _isListening = false);

    if (result != null && result.isNotEmpty) {
      widget.onResult(result);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No speech detected. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isListening ? null : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? Colors.red : const Color(0xFF6B5B95),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                  : [],
            ),
            child: _isListening
                ? RotationTransition(
                    turns: _animationController,
                    child: const Icon(Icons.mic, color: Colors.white, size: 30),
                  )
                : const Icon(Icons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening ? 'Listening...' : widget.hint ?? 'Tap to speak',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}