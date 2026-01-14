// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart'; // import ตัวนี้
import 'package:interact_app_2309/pages/login_page.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // เพิ่มบรรทัดนี้ เพื่อให้คีย์บอร์ดทำงานได้ครอบคลุมทุกหน้า
      builder: OnscreenKeyboard.builder(
        theme: OnscreenKeyboardThemeData.gBoard(), // หรือ .gBoard()
      ),
      home: const LoginPage(),
    );
  }
}