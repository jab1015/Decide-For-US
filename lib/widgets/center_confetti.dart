import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class CenterConfetti extends StatefulWidget {
  final bool trigger;

  const CenterConfetti({
    super.key,
    required this.trigger,
  });

  @override
  State<CenterConfetti> createState() => _CenterConfettiState();
}

class _CenterConfettiState extends State<CenterConfetti> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        ConfettiController(duration: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(covariant CenterConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.trigger && !oldWidget.trigger) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.03,
          numberOfParticles: 25,
          gravity: 0.25,
          shouldLoop: false,
          colors: const [
            Color(0xFF6A5AE0),
            Color(0xFF00C9A7),
            Color(0xFFFFC371),
            Color(0xFFFF5F6D),
          ],
          createParticlePath: drawRectangle,
        ),
      ),
    );
  }

  Path drawRectangle(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }
}
