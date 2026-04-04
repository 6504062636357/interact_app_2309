import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'homepage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _doSignup() async {
    setState(() => _loading = true);

    try {
      // 1. สมัครสมาชิกผ่าน Firebase
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(), // ตรวจสอบว่าต้อง >= 6 ตัวอักษร
      );

      await credential.user!.updateDisplayName(_name.text.trim());

      // 2. Sync ข้อมูลกับ MongoDB และ "เก็บค่าที่ส่งกลับมา"
      if (credential.user != null) {
        final response = await ApiService.syncUserToMongo(
          uid: credential.user!.uid,
          email: _email.text.trim(),
          name: _name.text.trim(),
        );
        if (!mounted) return;
        if (response != null) {
          // 3. เปลี่ยนหน้าไปยัง HomePage พร้อมข้อมูล User จริงจาก DB
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(userData: response), // ใช้ข้อมูลที่ได้จาก API
            ),
          );
        } else {
          throw Exception("ไม่สามารถสร้างข้อมูลในฐานข้อมูลได้");
        }
      }
    } on FirebaseAuthException catch (e) {
      // จัดการ Error จาก Firebase (เช่น weak-password)
      String message = e.code == 'weak-password'
          ? "Password must be at least 6 characters"
          : e.message ?? "Signup failed";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  )
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🔥 Title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Name
                  const Text("Full Name"),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      hintText: "Your name",
                      filled: true,
                      fillColor: Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Email
                  const Text("Email"),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      hintText: "example@gmail.com",
                      filled: true,
                      fillColor: Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Password
                  const Text("Password"),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _doSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A6CF7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _loading ? "Creating Account..." : "Create Account",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}