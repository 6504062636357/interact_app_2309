import 'package:flutter/material.dart';
import 'package:interact_app_2309/pages/PaymentPage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/class_schedule.model.dart';
import '../model/course.model.dart';
import 'dart:convert';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enrolled in ${widget.course.title}")),
        );
      } else {
        throw Exception("Enrollment failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              /// 🎬 VIDEO (โค้งด้านล่าง)
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _isInitialized && _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),

              /// 📄 CONTENT
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    /// 🔹 TITLE + PRICE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "${widget.course.price} THB",
                          style: const TextStyle(
                            color: Color(0xFF4A68FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "6h 14min · 24 Lessons",
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 25),

                    /// 🔹 ABOUT
                    const Text(
                      "About this course",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      widget.course.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.person, size: 18, color: Colors.orange),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.course.instructor,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    /// 🔹 LESSON (เหลือแค่ 01)
                    _buildLessonTile(
                        "01", "Welcome to the Course", "6:10 mins"),
                  ]),
                ),
              ),
            ],
          ),

          /// 💰 BUTTON
          _buildBottomButton(),
        ],
      ),
    );
  }

  /// 🔥 LESSON CARD (ใหม่)
  Widget _buildLessonTile(String no, String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            no,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF4A68FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 🔻 BUTTON ล่าง
  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.star_outline, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A68FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PaymentPage(course: widget.course),
                      ),
                    );
                  },
                  child: const Text(
                    "Buy Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}