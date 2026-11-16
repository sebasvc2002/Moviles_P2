import 'package:flutter/material.dart';

/// Botón de micrófono con un halo pulsante mientras se está grabando.
///
/// **SRP:** solo representa el estado de grabación; no sabe nada del motor de
/// voz. Quien lo usa decide qué hacer en [onPressed].
class VoiceDictationBtn extends StatefulWidget {
  /// Crea el botón. [isListening] activa la animación de pulso.
  const VoiceDictationBtn({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  /// Indica si hay un dictado en curso (muestra el ícono de detener).
  final bool isListening;

  /// Acción al pulsar; `null` deshabilita el botón.
  final VoidCallback? onPressed;

  @override
  State<VoiceDictationBtn> createState() => _VoiceDictationBtnState();
}

class _VoiceDictationBtnState extends State<VoiceDictationBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isListening) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant VoiceDictationBtn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final active = widget.isListening;

    return Semantics(
      button: true,
      label: active ? 'Detener dictado' : 'Dictar por voz',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.6 * (1 - t) + 0.2),
                        blurRadius: 8 + 12 * t,
                        spreadRadius: 2 + 6 * t,
                      ),
                    ]
                  : const [],
            ),
            child: child,
          );
        },
        child: Material(
          color: active ? accent : const Color(0xFF2A2A2A),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: active ? 'Detener dictado' : 'Dictar por voz',
            icon: Icon(
              active ? Icons.stop_rounded : Icons.mic_none_rounded,
              color: active ? Colors.white : accent,
            ),
            onPressed: widget.onPressed,
          ),
        ),
      ),
    );
  }
}
