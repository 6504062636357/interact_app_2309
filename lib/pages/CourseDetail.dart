import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/class_schedule.model.dart';
import '../model/course.model.dart';
import '../pages/BookingPage.dart';

import 'dart:convert';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late VideoPlayerController _videoPlayerController;//ต้องประกาศตัวแปรที่จะใช้ฟังชันด้วย
  late Future<List<ClassSchedule>> _futureSchedules;

  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
    _futureSchedules = getClassSchedules(widget.course.id);
  }

  void _initVideoPlayer() async {
    final String videoSource = widget.course.videoUrl.isNotEmpty
        ? widget.course.videoUrl
        : "https://interactedu.space/UARO.mp4";

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(videoSource));

    try {
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Video error: $e");
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  Future<List<ClassSchedule>> getClassSchedules(String courseId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/class-schedules/course/$courseId'), //ชี้ไปที่ที่อยู่ของ api

    );

    final List data = jsonDecode(res.body);
    return data.map((e) => ClassSchedule.fromJson(e)).toList();
  }
  // ฟังก์ชันลงทะเบียนเรียน (เหมือนเดิม)
  // 🔐 ใช้ FirebaseAuth แทน getToken()
  Future<void> _enrollCourse(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    try {
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/enrollments'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "courseId": widget.course.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enrolled in ${widget.course.title}")),
        );
      } else {
        throw Exception(data['message'] ?? "Enrollment failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enroll in Course"),
        content: Text("Confirm enrollment in '${widget.course.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _enrollCourse(context),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isInitialized && _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      widget.course.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    const Text("About this course", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      widget.course.description,
                      style: TextStyle(color: Colors.grey[800], fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 15),
                    Text("Instructor: ${widget.course.instructor}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),

                    const SizedBox(height: 40),

                    // รายการบทเรียน
                    _buildLessonTile("01", "Welcome to the Course", "6:10 mins", true),
                    _buildLessonTile("02", "Course Overview", "10:00 mins", false),
                  ]),
                ),



              ),
            ],
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Container(
              height: 55, width: 55,
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.star_outline, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A68FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(course: widget.course),
                      ),
                    );
                  },

                  child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(String no, String title, String time, bool isPlayed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Text(no, style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: Color(0xFF4A68FF), fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.play_circle_outline, color: Color(0xFF4A68FF), size: 45),
        ],
      ),
    );
  }

 // void _showPurchaseDialog(BuildContext context, String title) {
 //    showDialog(
 //      context: context,
 //      builder: (context) => AlertDialog(
 //        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 //        title: const Text("Enroll in Course"),
 //        content: Text("Confirm purchase for '$title'?"),
 //        actions: [
 //          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
 //          ElevatedButton(onPressed: () => _enrollCourse(context), child: const Text("Confirm")),
 //        ],
 //      ),
 //    );
 //  }
}
