import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: OnscreenKeyboard.builder(
        theme: OnscreenKeyboardThemeData.gBoard(),
      ),
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(),
        useMaterial3: true,
      ),
      home: const OnboardingPage(),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลา 3 วินาทีก่อนไปหน้า Login
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. ส่วนของโลโก้ (ปรับขนาดลงเหลือ 0.6)
            Image.asset(
              'assets/logo_interactedu.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
            ),

            // 2. เว้นระยะห่างระหว่างรูปกับตัวโหลด
            const SizedBox(height: 50),

            // 3. เครื่องหมายโหลด (Loading Indicator)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF264E5E)), // สีน้ำเงินเข้มตามโลโก้
              strokeWidth: 3.0, // ความหนาของเส้น
            ),

            const SizedBox(height: 20),

            // 4. ข้อความประกอบ (ใส่หรือไม่ใส่ก็ได้)
            Text(
              "กำลังเข้าสู่ระบบ...",
              style: GoogleFonts.kanit(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}