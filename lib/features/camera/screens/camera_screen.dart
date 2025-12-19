import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jisu_calendar/features/ai/screens/ai_chat_screen.dart';
import 'package:jisu_calendar/features/authentication/widgets/breathing_camera_button.dart';
import 'package:jisu_calendar/services/ocr_service.dart';
import 'package:jisu_calendar/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool _isInitialized = false;
  bool _controllerDisposed = false;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = const OcrService();
  bool _isOcrBusy = false;

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
    if (_controllerDisposed) return;
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
    _disposeCameraController();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controllerDisposed) return;
    try {
      final XFile imageFile = await _controller.takePicture();
      if (mounted) {
        await _runOcr(imageFile.path);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _openGallery({bool runOcr = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      if (runOcr) {
        await _runOcr(image.path);
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isInitialized || _controllerDisposed) return;
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

  Future<void> _runOcr(String imagePath) async {
    if (_isOcrBusy || !mounted) return;
    setState(() {
      _isOcrBusy = true;
    });

    final provider = context.read<AiChatProvider>();

    // 确保会话存在
    if (provider.currentSession == null) {
      await provider.createNewSession();
    }

    // 跳转到 AI 聊天，先占位提示“识别中...”
    provider.addLocalAssistantMessage('识别中...');

    await _disposeCameraController();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiChatScreen()),
      );
    }

    try {
      final text = await _ocrService.recognize(imagePath);
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        provider.updateLastAssistantMessage('未识别到文字，请重试');
      } else {
        provider.updateLastAssistantMessage('识别完成，正在发送…');
        provider.sendMessage('帮我添加日程：$trimmed');
      }
    } catch (e) {
      provider.updateLastAssistantMessage('识别失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isOcrBusy = false;
        });
      }
    }
  }

  Future<void> _goToAiChatWithText(String text) async {
    final prefixed = '帮我添加日程：$text';
    final provider = context.read<AiChatProvider>();

    if (provider.currentSession == null) {
      await provider.createNewSession();
    }

    provider.sendMessage(prefixed);

    await _disposeCameraController();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiChatScreen()),
    );
  }

  Future<void> _disposeCameraController() async {
    if (_controllerDisposed) return;
    if (_flashMode == FlashMode.torch && _isInitialized) {
      try {
        await _controller.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
    if (_isInitialized) {
      try {
        await _controller.dispose();
      } catch (_) {}
    }
    _controllerDisposed = true;
    _isInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
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
                  AnimatedOpacity(
                    opacity: _areControlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: IconButton(
                      onPressed: _isOcrBusy ? null : () => _openGallery(runOcr: true),
                      icon: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
