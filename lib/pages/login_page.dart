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
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  Future<void> _syncUserToFirestore({
    required String name,
    required String role,
    required String uid,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'displayName': name,
      'role': role,
      'authUid': uid,
      'photoUrl': "",
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Validate fields before submitting
  bool _validate() {
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (_email.text.trim().isEmpty) {
        _emailError = "Please enter your email address";
        valid = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.text.trim())) {
        _emailError = "Please enter a valid email address";
        valid = false;
      }

      if (_password.text.isEmpty) {
        _passwordError = "Please enter your password";
        valid = false;
      } else if (_password.text.length < 6) {
        _passwordError = "Password must be at least 6 characters";
        valid = false;
      }
    });
    return valid;
  }

  /// Show network error dialog (Netflix style)
  void _showNetworkError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 40, color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 20),
              const Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please check your connection and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Try Again",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show general error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 40, color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Got it",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doLogin() async {
    // Clear field errors first
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signOut();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text, // ❌ ห้าม trim password
      );

      final user = credential.user;

      if (user != null) {
        final userData = await ApiService.syncUserToMongo(
          uid: user.uid,
          email: user.email ?? "",
          name: user.displayName ?? "User",
        );

        if (!mounted) return;

        if (userData != null) {
          String role = userData['role'] ?? 'student';
          String name = userData['name'] ?? 'User';

          await _syncUserToFirestore(name: name, role: role, uid: user.uid);

          if (role == 'teacher') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => TeacherDashboard(userData: userData)));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => HomePage(userData: userData)));
          }
        } else {
          _showErrorDialog(
            "Something went wrong",
            "We couldn't load your profile. Please try again.",
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        // ❗ Highlight fields แทน Dialog
          setState(() {
            _emailError = "Incorrect email or password";
            _passwordError = "Incorrect email or password";
          });
          break;

        case 'invalid-email':
          setState(() => _emailError = "Please enter a valid email address");
          break;

        case 'user-disabled':
          _showErrorDialog(
            "Account Suspended",
            "Your account has been disabled. Please contact support.",
          );
          break;

        case 'too-many-requests':
          _showErrorDialog(
            "Too Many Attempts",
            "Your account is temporarily locked. Please wait a moment before trying again.",
          );
          break;

        case 'network-request-failed':
          _showNetworkError();
          break;

        default:
          _showErrorDialog("Sign In Failed", e.message ?? "An unexpected error occurred. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
        _showNetworkError();
      } else {
        _showErrorDialog(
          "Something went wrong",
          "An unexpected error occurred. Please try again.",
        );
      }
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
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back 👋",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Sign in to continue",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 28),

                  // ── Email ──
                  const Text("Email address",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _emailError = null),
                    decoration: InputDecoration(
                      hintText: "example@gmail.com",
                      filled: true,
                      fillColor: _emailError != null
                          ? const Color(0xFFFFF0F0)
                          : const Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _emailError != null
                            ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _emailError != null
                              ? const Color(0xFFE53935)
                              : const Color(0xFF4A6CF7),
                          width: 1.5,
                        ),
                      ),
                      errorText: _emailError,
                      errorStyle: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Password ──
                  const Text("Password",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword == true,
                    onChanged: (_) => setState(() => _passwordError = null),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _passwordError != null
                          ? const Color(0xFFFFF0F0)
                          : const Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _passwordError != null
                            ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordError != null
                              ? const Color(0xFFE53935)
                              : const Color(0xFF4A6CF7),
                          width: 1.5,
                        ),
                      ),
                      errorText: _passwordError,
                      errorStyle: const TextStyle(fontSize: 12),
                      // ✅ ลูกตาใช้งานได้จริง
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  // ── Forgot Password ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4A6CF7),
                      ),
                      child: const Text("Forgot password?",
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Login Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        disabledBackgroundColor: const Color(0xFF4A6CF7).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Create Account ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SignUpPage())),
                        child: const Text(
                          "Sign up",
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