// lib/models/course_model.dart

class CourseModel {
  final String id;
  final String title;
  final String description;
  final int totalLessons;
  final String imageUrl;
  final String videoUrl;
  final bool isHotCourse;
  final String category;
  final String instructor;
  final int price;
  final int durationHours;
  final String time;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.totalLessons,
    required this.imageUrl,
    required this.videoUrl,
    required this.isHotCourse,
    required this.category,
    required this.instructor,
    required this.price,
    required this.durationHours,
    required this.time,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'No Title',
        description: json['description']?.toString() ?? '',
        totalLessons: int.tryParse(json['totalLessons'].toString()) ?? 0,
        imageUrl: json['imageUrl']?.toString() ?? '',

        // 3. ดึงค่า videoUrl จาก JSON (ถ้าใน DB ไม่มี ให้ใส่ค่าว่างไว้ก่อน)
        videoUrl: json['videoUrl']?.toString() ?? '',

        isHotCourse: json['isHotCourse'] == true,
        category: json['category']?.toString() ?? 'General',
        instructor: json['instructor']?.toString() ?? 'Unknown Teacher',
        price: int.tryParse(json['price'].toString()) ?? 0,
        durationHours: int.tryParse(json['durationHours'].toString()) ?? 0,
        time: json['time']?.toString() ?? ''
    );
  }
}