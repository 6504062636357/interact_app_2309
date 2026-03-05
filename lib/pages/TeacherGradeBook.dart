import 'package:flutter/material.dart';

class TeacherGradeBook extends StatelessWidget {
  const TeacherGradeBook({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Grade Book")),
      body: const Center(
        child: Text("This is Grade Book Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}