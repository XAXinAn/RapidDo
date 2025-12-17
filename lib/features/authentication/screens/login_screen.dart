import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jisu_calendar/common/utils/validators.dart';
import 'package:jisu_calendar/features/authentication/screens/verification_code_screen.dart';
import 'package:jisu_calendar/features/authentication/widgets/gradient_action_button.dart';
import 'package:jisu_calendar/features/authentication/widgets/other_login_method_button.dart';
import 'package:jisu_calendar/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _loginInputController;
  bool _isEmailMode = false;
  bool _isRegisterMode = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loginInputController = TextEditingController();
  }

  @override
  void dispose() {
    _loginInputController.dispose();
    super.dispose();
  }

  void _loginWithWeChat() {
    // TODO: 实现微信登录功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('微信登录功能开发中...')),
    );
  }

  Future<void> _handleNextStep() async {
    final input = _loginInputController.text.trim();
    
    // 验证输入
    String? errorMessage;
    if (_isEmailMode) {
      errorMessage = Validators.validateEmail(input);
    } else {
      errorMessage = Validators.validatePhone(input);
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 仅手机号模式调用发送验证码API
      if (!_isEmailMode) {
        final response = await _authService.sendVerificationCode(input);
        
        print('发送验证码响应: success=${response.success}, message=${response.message}');
        
        if (response.success) {
          // 跳转到验证码页面
          if (mounted) {
            print('准备跳转到验证码页面');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VerificationCodeScreen(
                  loginIdentifier: input,
                  isEmail: _isEmailMode,
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? '发送验证码失败')),
            );
          }
        }
      } else {
        // 邮箱模式暂时提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('邮箱登录功能开发中...')),
          );
        }
      }
    } catch (e) {
      print('发送验证码异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const animationDuration = Duration(milliseconds: 300);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.blue[50]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/icon.png',
                  height: 100,
                  width: 100,
                ),
                AnimatedOpacity(
                  opacity: _isRegisterMode ? 1.0 : 0.0,
                  duration: animationDuration,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: Text(
                      '你好, 欢迎注册极速日历',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                TextField(
                  controller: _loginInputController,
                  keyboardType: _isEmailMode
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.75),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    hintText: _isEmailMode ? '请输入邮箱' : '请输入手机号',
                    hintStyle: TextStyle(color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
  ),
                ),
                const SizedBox(height: 24),
                GradientActionButton(
                  label: _isRegisterMode ? '立即注册' : '下一步',
                  onPressed: _isLoading ? () {} : () => _handleNextStep(),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _isRegisterMode ? 0.0 : 1.0,
                  duration: animationDuration,
                  child: Row(
                    children: [
                      Expanded(
                        child: _isEmailMode
                            ? OtherLoginMethodButton(
                                icon: Icons.phone_android,
                                label: '手机号登录',
                                onPressed: () {
                                  setState(() {
                                    _isEmailMode = false;
                                  });
                                },
                              )
                            : OtherLoginMethodButton(
                                icon: Icons.email_outlined,
                                label: '邮箱登录',
                                onPressed: () {
                                  setState(() {
                                    _isEmailMode = true;
                                  });
                                },
                              ),
                      ),
                      Expanded(
                        child: OtherLoginMethodButton(
                          icon: FontAwesomeIcons.weixin,
                          label: '微信登录',
                          onPressed: _loginWithWeChat,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                        });
                      },
                      style: ButtonStyle(
                        overlayColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      child: Text(_isRegisterMode ? '返回登录' : '注册账号',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 14)),
                    ),
                    const Text('|', style: TextStyle(color: Colors.black26)),
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        overlayColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      child: const Text('遇到问题',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
