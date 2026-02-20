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

  // ⭐ เพิ่มใหม่
  final String instructorImage;
  final double rating;
  final bool isBookmarked;

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

    required this.instructorImage,
    required this.rating,
    required this.isBookmarked,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      totalLessons: int.tryParse(json['totalLessons']?.toString() ?? '0') ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      isHotCourse: json['isHotCourse'] == true,
      category: json['category']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationHours:
      int.tryParse(json['durationHours']?.toString() ?? '0') ?? 0,
      time: json['time']?.toString() ?? '',

      instructorImage: json['instructorImage']?.toString() ?? '',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      isBookmarked: json['isBookmarked'] ?? false,

    );
  }
}
