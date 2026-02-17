import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/course.model.dart';
import 'package:http/http.dart' as http;
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

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        color: Colors.white,
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: () => _showPurchaseDialog(context),
            child: const Text("Buy Now"),
          ),
        ),
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
                    const SizedBox(height: 10),
                    Text("${widget.course.price} THB"),
                    const SizedBox(height: 20),
                    Text(widget.course.description),
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
}
