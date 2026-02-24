import 'package:flutter/material.dart';
import 'package:interact_app_2309/pages/edit_profile_page.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _futureMe;

  @override
  void initState() {
    super.initState();
    _futureMe = ApiService.getMe();
  }

  void _reload() {
    setState(() {
      _futureMe = ApiService.getMe();
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pop(
      context,
    ); // กลับไปหน้าที่แล้ว (ถ้าใช้ pushReplacement ตอน login อาจต้องเปลี่ยนเป็นไปหน้า Login)
  }

  String _s(dynamic v) => (v == null) ? "" : v.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureMe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Load profile failed",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text("Try again"),
                    ),
                  ],
                ),
              ),
            );
          }

          final me = snapshot.data ?? {};
          final name = _s(me["name"]);
          final email = _s(me["email"]);
          final role = _s(me["role"]);
          final phone = _s(me["phone"]);
          final bio = _s(me["bio"]);
          final goalMinutes = _s(me["goalMinutes"]);
          final learnedToday = _s(me["learnedToday"]);
          final photoUrl = _s(me["photoUrl"]);
          final authUid = _s(me["authUid"]);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name.isEmpty ? "No name" : name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(email, style: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  title: const Text("Role"),
                  subtitle: Text(role),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Auth UID"),
                  subtitle: Text(authUid),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Phone"),
                  subtitle: Text(phone.isEmpty ? "-" : phone),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Bio"),
                  subtitle: Text(bio.isEmpty ? "-" : bio),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Goal Minutes"),
                  subtitle: Text(goalMinutes.isEmpty ? "-" : goalMinutes),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Learned Today"),
                  subtitle: Text(learnedToday.isEmpty ? "-" : learnedToday),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _reload,
                child: const Text("Reload Profile"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );

                  if (updated == true) {
                    _reload();
                  }
                },
                child: const Text("Edit Profile"),
              ),
            ],
          );
        },
      ),
    );
  }
}
