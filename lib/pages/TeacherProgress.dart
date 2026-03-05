import 'package:flutter/material.dart';

class TeacherProgress extends StatelessWidget {
  const TeacherProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Progress")),
      body: const Center(
        child: Text("This is Progress Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}