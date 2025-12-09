import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jisu_calendar/features/authentication/widgets/breathing_camera_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool _isInitialized = false;
  final ImagePicker _picker = ImagePicker();

  bool _areControlsVisible = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _areControlsVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_flashMode == FlashMode.torch) {
      _controller.setFlashMode(FlashMode.off);
    }
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) return;
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

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已选择图片: ${image.path}')),
      );
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isInitialized) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      print('Failed to set flash mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60.0,
              color: Colors.black,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: AnimatedOpacity(
                    opacity: _areControlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        Icons.bolt,
                        color: _flashMode == FlashMode.torch
                            ? Colors.yellow
                            : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: _isInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: 1 / _controller.value.aspectRatio,
                          child: CameraPreview(_controller),
                        ),
                      )
                    : Container(),
              ),
            ),
            Container(
              height: 240.0,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedOpacity(
                    opacity: _areControlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: IconButton(
                      onPressed: _openGallery,
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                    ),
                  ),
                  Hero(
                    tag: 'camera_button_hero',
                    // Add the same flight shuttle builder here
                    flightShuttleBuilder: (flightContext, animation, flightDirection,
                        fromHeroContext, toHeroContext) {
                      return BreathingCameraButton(
                        onPressed: () {},
                        animate: false, // Disable animation during flight
                        lightColor: Colors.white, // Ensure color consistency
                      );
                    },
                    child: BreathingCameraButton(
                      onPressed: _takePicture,
                      lightColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
