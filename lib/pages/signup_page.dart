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
        // ✅ แก้ไข: ต้องกำหนดค่าให้ userData จากผลลัพธ์ของฟังก์ชัน
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
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _doSignup,
              child: Text(
                _loading ? "Creating Account..." : "Create Account",
              ),
            ),
          ],
        ),
      ),
    );
  }
}