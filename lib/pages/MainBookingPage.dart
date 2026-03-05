import 'package:flutter/material.dart';
import '../services/api_service.dart'; // เรียกใช้ Service สำหรับดึงข้อมูล
import '../model/course.model.dart';   // เรียกใช้ Model ข้อมูลคอร์ส
import 'BookingPage.dart';             // Import หน้า BookingPage สำหรับเปลี่ยนหน้า

class MainBookingPage extends StatefulWidget {
  const MainBookingPage({super.key});

  @override
  State<MainBookingPage> createState() => _MainBookingPageState();
}

class _MainBookingPageState extends State<MainBookingPage> {
  // --- ตัวแปรสำหรับจัดการสถานะข้อมูล ---
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookingCourses(); // เริ่มดึงข้อมูลเมื่อหน้าจอถูกสร้าง
  }

  // --- ฟังก์ชันดึงข้อมูลจาก API/Database ---
  Future<void> _fetchBookingCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // เรียกใช้ ApiService ดึงรายการคอร์ส
      final List<dynamic> courseData = await ApiService.getCourses();

      setState(() {
        _courses = courseData.map((json) => CourseModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถดึงข้อมูลได้: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D6D), // พื้นหลังสีน้ำเงินเข้มตามรูปภาพ
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------------- HEADER ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Booking",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Let's start learning",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const Icon(Icons.chat_bubble, color: Colors.white), // ไอคอนแชทตามดีไซน์
                ],
              ),
            ),

            // ---------------- รายการคอร์สที่ดึงมาจาก DB ----------------
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ส่วนแสดงผลเนื้อหา (จัดการสถานะ Loading และ Error) ---
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }
    if (_courses.isEmpty) {
      return const Center(child: Text("ไม่มีคอร์สสำหรับการจองในขณะนี้"));
    }

    return RefreshIndicator(
      onRefresh: _fetchBookingCourses, // ดึงข้อมูลใหม่เมื่อใช้นิ้วลากลง
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];

          // สลับสีพื้นหลัง Card ตามดีไซน์ต้นฉบับ
          List<Color> cardColors = [
            const Color(0xFFFFF9E5), // เหลืองนวล
            const Color(0xFFE5F6FF), // ฟ้าอ่อน
            const Color(0xFFE5FFFA), // เขียวมิ้นต์
          ];

          return _buildBookingCard(
            course: course,
            bgColor: cardColors[index % cardColors.length],
          );
        },
      ),
    );
  }

  // --- Widget สำหรับสร้างแต่ละ Card คอร์ส ---
  Widget _buildBookingCard({
    required CourseModel course,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปภาพคอร์ส (ถ้าไม่มีรูปแสดงไอคอนโรงเรียนแทน)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              image: course.imageUrl.isNotEmpty
                  ? DecorationImage(
                  image: NetworkImage(course.imageUrl),
                  fit: BoxFit.cover)
                  : null,
            ),
            child: course.imageUrl.isEmpty
                ? const Icon(Icons.school, size: 45, color: Colors.blueGrey)
                : null,
          ),
          const SizedBox(width: 15),

          // รายละเอียดข้อมูลคอร์ส
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    const Text("4.5", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      "• ${course.durationHours}h total",
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${course.price} Bath",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D6D)
                      ),
                    ),
                    // ปุ่มยืนยันการนำทางไปยังหน้า BookingPage
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(course: course),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // ปุ่มสีส้มตามรูปภาพ
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}