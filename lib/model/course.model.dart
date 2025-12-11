// lib/models/course_model.dart

class CourseModel {
  final String id;
  final String title;
  final String description;
  final int totalLessons;
  final String imageUrl;
  final bool isHotCourse;
  final String category;
  final String instructor;
  final int price;
  final int durationHours;
  // final DateTime createdAt; // ตัดออกก่อนเพื่อลดความซับซ้อนของวันที่

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.totalLessons,
    required this.imageUrl,
    required this.isHotCourse,
    required this.category,
    required this.instructor,
    required this.price,
    required this.durationHours,
    // required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? '',

      // การแปลงตัวเลขที่ปลอดภัย (รับได้ทั้ง String และ Int)
      totalLessons: int.tryParse(json['totalLessons'].toString()) ?? 0,

      // ถ้าไม่มีรูป ให้ใช้รูป Placeholder
      imageUrl: json['imageUrl']?.toString() ?? '',

      isHotCourse: json['isHotCourse'] == true,

      // *** จุดที่แก้ Error: ถ้าไม่มีข้อมูล ให้ใส่ค่า Default ***
      category: json['category']?.toString() ?? 'General',
      instructor: json['instructor']?.toString() ?? 'Unknown Teacher',
      price: int.tryParse(json['price'].toString()) ?? 0,
      durationHours: int.tryParse(json['durationHours'].toString()) ?? 0,
    );
  }
}