import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

class AppVoiceSearchBar extends StatefulWidget {
  const AppVoiceSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged,
    this.hintText,
    this.surfaceColor,
    this.foregroundColor,
    this.height = 48,
    this.localeId,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  final Color? surfaceColor;
  final Color? foregroundColor;
  final double height;
  final String? localeId;

  @override
  State<AppVoiceSearchBar> createState() => _AppVoiceSearchBarState();
}

class _AppVoiceSearchBarState extends State<AppVoiceSearchBar>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  late final AnimationController _pulseController;
  bool _speechAvailable = false;
  bool _initStarted = false;
  bool _isListening = false;
  String? _statusMessage;
  Timer? _autoStopTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _ensureInitialized() async {
    if (_speechAvailable || _initStarted) return;
    _initStarted = true;
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' || status == 'done') {
      _stopListening(showHint: false);
    }
  }

  void _handleError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _statusMessage = _humanizeError(error.errorMsg);
      _isListening = false;
    });
    _pulseController.stop();
  }

  String _humanizeError(String code) {
    switch (code) {
      case 'error_speech_timeout':
      case 'error_no_match':
        return "Didn't catch that — try again";
      case 'error_permission':
      case 'error_audio':
        return 'Microphone permission needed';
      case 'error_network':
      case 'error_network_timeout':
        return 'Network unavailable';
      default:
        return 'Voice search unavailable';
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    await _ensureInitialized();
    if (!_speechAvailable) {
      setState(() => _statusMessage = 'Microphone permission needed');
      return;
    }
    setState(() {
      _statusMessage = null;
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(const Duration(seconds: 12), () {
      if (_isListening) _stopListening();
    });
    await _speech.listen(
      onResult: _handleResult,
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
        localeId: widget.localeId,
        partialResults: true,
        listenMode: stt.ListenMode.search,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListening({bool showHint = true}) async {
    _autoStopTimer?.cancel();
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (!mounted) return;
    _pulseController.stop();
    setState(() {
      _isListening = false;
      if (showHint == false) _statusMessage = null;
    });
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) widget.onSubmitted(text);
  }

  void _handleResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords;
    widget.controller.value = TextEditingValue(
      text: transcript,
      selection: TextSelection.collapsed(offset: transcript.length),
    );
    widget.onChanged?.call(transcript);
    if (result.finalResult) {
      _stopListening();
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    widget.controller.removeListener(_handleControllerChange);
    _pulseController.dispose();
    if (_speech.isListening) _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = widget.surfaceColor ??
        (isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.95));
    final fg = widget.foregroundColor ?? scheme.onSurface;
    final hintColor = scheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppSpacing.roundedXxl,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
                child: Icon(Icons.search_rounded, color: hintColor, size: 22),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(color: fg, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Search…',
                    hintStyle: TextStyle(color: hintColor, fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: hintColor, size: 20),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                    widget.onSubmitted('');
                  },
                ),
              _MicButton(
                isListening: _isListening,
                pulse: _pulseController,
                onTap: _toggleListening,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        if (_isListening || _statusMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6),
            child: Row(
              children: [
                if (_isListening) ...[
                  _ListeningDot(controller: _pulseController, color: context.palette.error),
                  const SizedBox(width: 6),
                  Text(
                    'Listening… speak now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ] else if (_statusMessage != null)
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.palette.warning,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isListening,
    required this.pulse,
    required this.onTap,
  });

  final bool isListening;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = context.palette.error;
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final t = pulse.value;
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isListening)
                      Container(
                        width: 32 + (t * 10),
                        height: 32 + (t * 10),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.18 - (t * 0.12)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isListening
                            ? activeColor
                            : scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none_rounded,
                        size: 18,
                        color: isListening ? Colors.white : scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ListeningDot extends StatelessWidget {
  const _ListeningDot({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4 + (controller.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
