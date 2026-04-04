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

  ///  Sync MongoDB → Firestore
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
      //  Login Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = credential.user;

      if (user != null) {

        // Sync กับ MongoDB และดึง user data
        final userData = await ApiService.syncUserToMongo(
          uid: user.uid,
          email: user.email ?? "",
          name: user.displayName ?? "User",
        );

        if (!mounted) return;

        if (userData != null) {

          String role = userData['role'] ?? 'student';
          String name = userData['name'] ?? 'User';

          // Sync ไป Firestore (ใช้สำหรับ Chat)
          await _syncUserToFirestore(
            name: name,
            role: role,
            uid: user.uid,
          );

          //  Redirect ตาม Role
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
                    "Log In",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Email Label
                  const Text("Your Email"),

                  const SizedBox(height: 8),

                  /// Email Field
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

                  /// Password Label
                  const Text("Password"),

                  const SizedBox(height: 8),

                  /// Password Field
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

                  /// Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forget password?",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A6CF7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _loading ? "Loading..." : "Log In",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Create account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Create account",
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