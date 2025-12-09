import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/authentication/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '极速日历',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color.fromRGBO(237, 237, 237, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(237, 237, 237, 1),
          elevation: 0, // Remove shadow
          scrolledUnderElevation: 0, // Remove shadow on scroll
          titleTextStyle: TextStyle( // Define global AppBar title style
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
