import 'package:flutter/material.dart';
import '../../model/course.model.dart';

class MyClassTab extends StatelessWidget {
  final List<CourseModel> courses;
  // ลบ Constructor ซ้ำซ้อนออก เหลือแค่อันนี้อันเดียว
  const MyClassTab({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Center(child: Text("No courses found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          title: course.title,
          teacher: course.instructor,
          hour: course.durationHours,
          imageUrl: course.imageUrl,
        );
      },
    );
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final String teacher;
  final int hour;
  final String imageUrl;

  const CourseCard({
    super.key,
    required this.title,
    required this.teacher,
    required this.hour,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(teacher, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (hour / 20).clamp(0.0, 1.0),
                  color: Colors.orange,
                  backgroundColor: Colors.orange.shade100,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}