import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpinButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final double rotation;

  const SpinButton({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.rotation,
  });

  @override
  State<SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<SpinButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: isPressed ? 0.94 : 1,
          child: AnimatedRotation(
            turns: widget.rotation,
            duration: const Duration(seconds: 8),
            curve: Curves.easeOutCubic,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: [
                  ...AppShadows.soft,
                  BoxShadow(
                    color: AppColors.primaryStart.withOpacity(0.35),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// 🔥 Glow ring
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryStart.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                  ),

                  /// 🎡 TEXT
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.casino, color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        widget.isLoading ? "SPINNING..." : "SPIN",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}