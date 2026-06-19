import 'dart:io';

import 'package:flutter/material.dart';

import '../services/voice_controller.dart';

class VoiceBar extends StatelessWidget {
  const VoiceBar({
    super.key,
    required this.controller,
  });

  final VoiceController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        final isRecording = status == VoiceBarStatus.recording;
        final isTranscribing = status == VoiceBarStatus.transcribing;
        final isPasting = status == VoiceBarStatus.pasting;
        final hasError = status == VoiceBarStatus.error;

        return GestureDetector(
          onTap: hasError ? () => controller.openAccessibilitySettings() : null,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xEE1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRecording
                      ? const Color(0xFFFF4D6D)
                      : hasError
                      ? const Color(0xFFFFB703)
                      : const Color(0xFF3D3D5C),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _StatusDot(
                    isRecording: isRecording,
                    isTranscribing: isTranscribing,
                    isPasting: isPasting,
                    hasError: hasError,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusLabel(status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          controller.errorMessage ?? _subtitle(status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasError
                                ? const Color(0xFFFFB703)
                                : Colors.white70,
                            fontSize: 11,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isRecording ? Icons.mic : Icons.mic_none,
                    color: isRecording
                        ? const Color(0xFFFF4D6D)
                        : Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(VoiceBarStatus status) {
    return switch (status) {
      VoiceBarStatus.idle => 'Voice Bar',
      VoiceBarStatus.recording => 'Recording…',
      VoiceBarStatus.transcribing => 'Transcribing…',
      VoiceBarStatus.pasting => 'Pasting text…',
      VoiceBarStatus.error => 'Error',
    };
  }

  String _subtitle(VoiceBarStatus status) {
    return switch (status) {
      VoiceBarStatus.idle => 'F5 start · F5 stop & paste',
      VoiceBarStatus.recording => 'Press F5 to stop',
      VoiceBarStatus.transcribing => 'Converting speech to text…',
      VoiceBarStatus.pasting => 'Inserting at cursor…',
      VoiceBarStatus.error => Platform.isWindows
          ? 'Tap to open microphone settings'
          : 'Tap to open Accessibility settings',
    };
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({
    required this.isRecording,
    required this.isTranscribing,
    required this.isPasting,
    required this.hasError,
  });

  final bool isRecording;
  final bool isTranscribing;
  final bool isPasting;
  final bool hasError;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.hasError
        ? const Color(0xFFFFB703)
        : widget.isRecording
        ? const Color(0xFFFF4D6D)
        : widget.isTranscribing
        ? const Color(0xFFB517FF)
        : widget.isPasting
        ? const Color(0xFF4CC9F0)
        : const Color(0xFF6C757D);

    return FadeTransition(
      opacity: widget.isRecording
          ? Tween<double>(begin: 0.45, end: 1).animate(_pulse)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
