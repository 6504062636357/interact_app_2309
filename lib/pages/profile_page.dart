import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await ApiService.getToken();
    setState(() => _token = t);
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pop(context); // กลับไปหน้า Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Center(
        child: _token == null
            ? const Text("No token found, please login again.")
            : Text("JWT Token:\n$_token"),
      ),
    );
  }
}
