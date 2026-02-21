import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _goalMinutes = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final me = await ApiService.getMe();

      _name.text = me["name"] ?? "";
      _phone.text = me["phone"] ?? "";
      _bio.text = me["bio"] ?? "";
      _goalMinutes.text = (me["goalMinutes"] ?? 60).toString();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Load failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await ApiService.updateMe(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
        goalMinutes: int.tryParse(_goalMinutes.text),
      );

      if (!mounted) return;

      Navigator.pop(context, true); // ส่งค่า true กลับไปเพื่อ refresh

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _goalMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),

            TextField(
              controller: _bio,
              decoration: const InputDecoration(labelText: "Bio"),
            ),

            TextField(
              controller: _goalMinutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Goal Minutes"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? "Saving..." : "Save"),
            ),
          ],
        ),
      ),
    );
  }
}