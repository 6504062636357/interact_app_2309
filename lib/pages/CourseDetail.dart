import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../config.dart';
import '../model/course.model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course; // รับข้อมูลคอร์สที่มี videoUrl มาจากหน้าแรก

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

  // ฟังก์ชันตั้งค่าตัวเล่นวิดีโอตาม URL ของแต่ละวิชา
  void _initVideoPlayer() async {
    // 1. ตรวจสอบว่ามี URL วิดีโอไหม ถ้าไม่มีให้ใช้ตัวอย่าง (UARO.mp4)
    final String videoSource = widget.course.videoUrl.isNotEmpty
        ? widget.course.videoUrl
        : "https://interactedu.space/UARO.mp4";

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoSource));

    try {
      await _videoPlayerController.initialize();

      // 2. ตั้งค่า Chewie (หน้าตา UI วิดีโอ)
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: false, // ให้กดเล่นเอง
        looping: false,
        placeholder: Container(color: Colors.black), // พื้นหลังระหว่างรอโหลด
        autoInitialize: true,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print("Error initializing video: $e");
    }
  }

  @override
  void dispose() {
    // 3. สำคัญมาก: ต้องล้างข้อมูล Controller เมื่อออกจากหน้า
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ฟังก์ชันลงทะเบียนเรียน (เหมือนเดิม)
  Future<void> _enrollCourse(BuildContext context) async {
    final String? myToken = await ApiService.getToken();
    if (myToken == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
      }
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/enroll');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $myToken",
        },
        body: jsonEncode({"course_id": widget.course.id}),
      );

      if (response.statusCode == 201 && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! ${widget.course.title} added to My Class")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot connect to server")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // --- 1. ส่วน Header: เปลี่ยนจากรูปเป็น Video Player ---
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 16 / 9, // ขนาดวิดีโอมาตรฐาน
                  child: Container(
                    color: Colors.black,
                    child: _isInitialized && _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ),

              // --- 2. รายละเอียดเนื้อหา (ใช้ widget.course เพื่อดึงข้อมูล) ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.course.title,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "${widget.course.price} THB",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A68FF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.course.time} · ${widget.course.totalLessons} Lessons",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
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

          // --- 3. ปุ่ม Back (Overlay อยู่ด้านบน) ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // --- 4. ปุ่ม Buy Now (Fixed Bottom) ---
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
                  onPressed: () => _showPurchaseDialog(context, widget.course.title),
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

  void _showPurchaseDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enroll in Course"),
        content: Text("Confirm purchase for '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => _enrollCourse(context), child: const Text("Confirm")),
        ],
      ),
    );
  }
}