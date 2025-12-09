import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/home/screens/home_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String loginIdentifier;
  final bool isEmail;

  const VerificationCodeScreen({
    super.key,
    required this.loginIdentifier,
    required this.isEmail,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _login() {
    // TODO: Implement code verification logic
    if (_codeController.text == '123456') { // Changed to 6 digits
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码错误')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayText = widget.isEmail
        ? widget.loginIdentifier
        : '+86 ${widget.loginIdentifier}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('输入验证码'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Image.asset(
                  'assets/icon.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  '验证码已发送至 $displayText',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6, // Limit to 6 digits
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6), // Adjusted spacing
                  decoration: InputDecoration(
                    counterText: '', // Hide the counter
                    border: InputBorder.none,
                    hintText: '请输入六位验证码', // Updated hint
                    hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400], letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: Implement resend code logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('验证码已重新发送')),
                    );
                  },
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: const Text('重新发送', style: TextStyle(color: Colors.blue)),
                ),
                const Spacer(flex: 2),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ).copyWith(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A77D2), Color(0xFF4AC4CF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      child: const Text(
                        '登录',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
