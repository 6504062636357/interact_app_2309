import 'package:flutter/material.dart';

class TeacherAccount extends StatelessWidget {
  const TeacherAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Account")),
      body: const Center(
        child: Text("This is Account Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}