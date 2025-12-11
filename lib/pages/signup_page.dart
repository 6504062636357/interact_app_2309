import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_page.dart';
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

  void _doSignup() async {
    setState(() => _loading = true);
    try {
      await ApiService.signup(_name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _doSignup,
              child: Text(_loading ? "Loading..." : "Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}
