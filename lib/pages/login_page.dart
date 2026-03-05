import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interact_app_2309/pages/signup_page.dart';
import 'homepage.dart';
import 'TeacherDashBoard.dart';
import '../services/api_service.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _doLogin() async {
    setState(() => _loading = true);

    try {
      // 1. Login ผ่าน Firebase Authentication
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = credential.user;

      if (user != null) {
        // 2. Sync ข้อมูลกับ MongoDB และดึงข้อมูล User (ที่มีฟิลด์ name และ role)
        final userData = await ApiService.syncUserToMongo(
          uid: user.uid,
          email: user.email ?? "",
          name: user.displayName ?? "User",
        );

        if (!mounted) return;

        // 3. ตรวจสอบว่าได้ข้อมูลจาก MongoDB มาจริงหรือไม่ เพื่อป้องกันหน้าจอแดง (Null Error)
        if (userData != null) {
          String role = userData['role'] ?? 'student';

          if (role == 'teacher') {
            // ส่ง userData ไปที่ TeacherDashboard เพื่อแสดงชื่อ "c21"
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherDashboard(userData: userData),
              ),
            );
          } else {
            // ส่ง userData ไปที่ HomePage สำหรับนักเรียน
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(userData: userData),
              ),
            );
          }
        } else {
          // กรณีดึงข้อมูลจาก MongoDB ไม่สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ไม่สามารถดึงข้อมูลผู้ใช้จากระบบได้")),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = "Invalid email or password";
          break;
        case 'invalid-email':
          message = "Invalid email format";
          break;
        case 'user-disabled':
          message = "This user has been disabled";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later";
          break;
        default:
          message = e.message ?? "Authentication error";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ), const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    // เด้งไปหน้า SignupPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _doLogin,
              child: Text(
                _loading ? "Loading..." : "Login",
              ),
            ),
          ],
        ),
      ),

    );
  }

}
