import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jisu_calendar/features/authentication/screens/verification_code_screen.dart';
import 'package:jisu_calendar/features/home/screens/home_screen.dart';
import 'package:jisu_calendar/features/authentication/widgets/gradient_action_button.dart';
import 'package:jisu_calendar/features/authentication/widgets/other_login_method_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _loginInputController;
  bool _isEmailMode = false;
  bool _isRegisterMode = false;

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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
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
                  onPressed: () {
                    if (_loginInputController.text.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VerificationCodeScreen(
                            loginIdentifier: _loginInputController.text,
                            isEmail: _isEmailMode,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Spacer(flex: 3),
                if (!_isRegisterMode)
                  Row(
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
