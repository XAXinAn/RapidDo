import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/authentication/widgets/breathing_camera_button.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    try {
      final XFile imageFile = await _controller.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍摄成功，照片保存在${imageFile.path}')),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: BreathingCameraButton(
                onPressed: _takePicture,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
