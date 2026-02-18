class ClassSchedule {
  final String id;
  final String courseId;
  final String teacherName;
  final double teacherRating;
  final String date;
  final String startTime;
  final String endTime;

  ClassSchedule({
    required this.id,
    required this.courseId,
    required this.teacherName,
    required this.teacherRating,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['_id'],
      courseId: json['courseId'], // ⭐ สำคัญมาก
      teacherName: json['teacherName'],
      teacherRating: (json['teacherRating'] ?? 0).toDouble(),
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}
