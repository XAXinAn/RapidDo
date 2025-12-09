import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/authentication/widgets/breathing_camera_button.dart';
import 'package:jisu_calendar/features/camera/screens/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主页'),
      ),
      body: Stack(
        children: [
          const Center(
            child: Text('欢迎!'),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: BreathingCameraButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
