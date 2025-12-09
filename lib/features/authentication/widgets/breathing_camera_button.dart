import 'package:flutter/material.dart';

class BreathingCameraButton extends StatefulWidget {
  const BreathingCameraButton({
    super.key,
    required this.onPressed,
    this.lightColor,
    this.animate = true, // New property to control animation
  });

  final VoidCallback onPressed;
  final Color? lightColor;
  final bool animate;

  @override
  State<BreathingCameraButton> createState() => _BreathingCameraButtonState();
}

class _BreathingCameraButtonState extends State<BreathingCameraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(BreathingCameraButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop(canceled: false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.lightColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Only show shadow if animating
            boxShadow: widget.animate
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.75),
                      blurRadius: _animation.value,
                      spreadRadius: _animation.value,
                    ),
                  ]
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8A78F2), Color(0xFF64D8D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
              ),
              child: const Icon(Icons.camera_alt, size: 32),
            ),
          ),
        );
      },
    );
  }
}
