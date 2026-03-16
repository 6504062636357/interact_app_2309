import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// ⭐ Sync MongoDB → Firestore
  Future<void> _syncUserToFirestore({
    required String name,
    required String role,
    required String uid,
  }) async {

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({

      'displayName': name,
      'role': role,
      'authUid': uid,
      'photoUrl': "",
      'lastActive': FieldValue.serverTimestamp(),

    }, SetOptions(merge: true));
  }

  Future<void> _doLogin() async {

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signOut();
      // 1️⃣ Login Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = credential.user;

      if (user != null) {

        // 2️⃣ Sync กับ MongoDB และดึง user data
        final userData = await ApiService.syncUserToMongo(
          uid: user.uid,
          email: user.email ?? "",
          name: user.displayName ?? "User",
        );

        if (!mounted) return;

        if (userData != null) {

          //String role = userData['role'] ?? 'student';
          // String role = userData['user']['role'] ?? 'student';
          // String name = userData['name'] ?? 'User';
          String role = userData['role'] ?? 'student';
          String name = userData['name'] ?? 'User';

          // ⭐ 3️⃣ Sync ไป Firestore (ใช้สำหรับ Chat)
          await _syncUserToFirestore(
            name: name,
            role: role,
            uid: user.uid,
          );

          // 4️⃣ Redirect ตาม Role
          if (role == 'teacher') {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherDashboard(userData: userData),
              ),
            );

          } else {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(userData: userData),
              ),
            );

          }

        } else {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ไม่สามารถดึงข้อมูลผู้ใช้จากระบบได้"),
            ),
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
      print("LOGIN ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }finally {

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
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text("Don't have an account?"),

                TextButton(
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpPage(),
                      ),
                    );

                  },

                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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