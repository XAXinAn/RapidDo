import 'package:flutter/material.dart';

class BreathingCameraButton extends StatefulWidget {
  const BreathingCameraButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

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
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.5),
                blurRadius: _animation.value,
                spreadRadius: _animation.value,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Icon(Icons.camera_alt, size: 32),
          ),
        );
      },
    );
  }
}
