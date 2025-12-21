import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isStartingFloating = false;
  bool _isFloatingRunning = false;
  StreamSubscription<Map<String, dynamic>>? _floatingSub;

  bool _areControlsVisible = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
    _listenFloatingEvents();
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
    _floatingSub?.cancel();
    _disposeCameraController();
    super.dispose();
  }

  void _listenFloatingEvents() {
    _floatingSub = _ocrService.floatingEvents().listen((event) async {
      final status = event['status']?.toString();
      if (!mounted) return;

      switch (status) {
        case 'ready':
          setState(() => _isFloatingRunning = true);
          _showSnack('悬浮截屏已就绪，点击悬浮球截屏');
          break;
        case 'capturing':
          setState(() => _isOcrBusy = true);
          _showSnack('截屏中…');
          break;
        case 'success':
          setState(() => _isOcrBusy = false);
          final text = (event['text'] ?? '').toString().trim();
          if (text.isEmpty) {
            _showSnack('未识别到文字');
            return;
          }
          // 悬浮窗原生侧已直接调用 AI（含去重），这里不再重复发送，避免重复创建会话/日程。
          // 日程刷新由 HomeScreen 的 didChangeAppLifecycleState(resumed) 统一处理
          _showSnack('已识别并发送，稍候查看悬浮窗结果');
          break;
        case 'error':
          setState(() => _isOcrBusy = false);
          final message = (event['message'] ?? '悬浮截屏出错').toString();
          _showSnack(message);
          break;
      }
    });
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

  Future<void> _startFloatingOcr() async {
    if (_isStartingFloating) return;
    setState(() => _isStartingFloating = true);
    try {
      await _ocrService.startFloatingOcr();
      if (!mounted) return;
      setState(() => _isFloatingRunning = true);
      _showSnack('悬浮截屏已启动，等待就绪');
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败：${e.code} ${e.message ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingFloating = false);
      }
    }
  }

  Future<void> _stopFloatingOcr() async {
    try {
      await _ocrService.stopFloatingOcr();
      if (!mounted) return;
      setState(() => _isFloatingRunning = false);
      _showSnack('悬浮截屏已关闭');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('关闭失败：$e')),
      );
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: _areControlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: IconButton(
                          onPressed: _openGallery,
                          icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                        ),
                      ),
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
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _areControlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: SizedBox(
                          height: 64,
                          width: 160,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _isOcrBusy ? null : () => _openGallery(runOcr: true),
                                  icon: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isStartingFloating
                                      ? null
                                      : (_isFloatingRunning ? _stopFloatingOcr : _startFloatingOcr),
                                  icon: Icon(
                                    _isFloatingRunning
                                        ? Icons.cancel_presentation
                                        : Icons.picture_in_picture_alt,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
