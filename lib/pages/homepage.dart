import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Import หน้าอื่นๆ สำหรับ Bottom Navigation Bar
import 'Account.dart';
import 'Course.dart';
import 'Message.dart';
import 'Search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _futureDashboard;
  int _selectedIndex = 0; // Index สำหรับ BottomNavigationBar

  // รายการ Widgets/Pages ที่จะใช้ใน Bottom Navigation Bar
  // สำหรับ Index 0 เราจะใช้ FutureBuilder เพื่อจัดการการดึงข้อมูล
  final List<Widget> _widgetOptions = <Widget>[
    Container(), // Placeholder สำหรับ Home, เนื้อหาจะถูกสร้างใน Body
    const CoursePage(),
    const SearchPage(),
    const MessagePage(),
    const AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _futureDashboard = ApiService.getDashboard();
  }

  // สร้าง App Bar สำหรับหน้า Home
  Widget _buildAppBar(String userName) { // รับชื่อผู้ใช้เข้ามา
    return Container(
      height: 120 + MediaQuery.of(context).padding.top, // ความสูงรวม Status Bar
      color: const Color(0xFF004D6D), // สีน้ำเงินเข้ม
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hi, $userName", // **ใช้ชื่อที่ดึงมาจาก DB**
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Icon Wi-Fi และ Battery (จำลอง) - จริงๆ แล้วควรอยู่เหนือ AppBar
              // แต่เราจำลองให้อยู่ในพื้นที่นี้ตามดีไซน์
              Row(
                children: const [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 4),
                  Icon(Icons.battery_full, color: Colors.white),
                ],
              ),
            ],
          ),
          const Text(
            "Let's start learning",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ไม่มี AppBar ใน Scaffold แล้ว
      body: Center(
        child: _selectedIndex == 0
            ? FutureBuilder<Map<String, dynamic>>(
          future: _futureDashboard,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              final data = snapshot.data!;
              // ใช้ข้อมูลจาก API หรือค่า Default
              final user = data["user"] ?? {"name": "User", "learnedToday": 0, "goalMinutes": 0};

              return Column(
                children: [
                  // Header ที่ปรับเปลี่ยนให้แสดงชื่อจาก API
                  _buildAppBar(user['name']),
                  // เนื้อหาที่เหลือที่เลื่อนได้
                  Expanded(
                    child: SingleChildScrollView(
                      child: _HomeContent(data: data),
                    ),
                  ),
                ],
              );
            }
          },
        )
            : _widgetOptions.elementAt(_selectedIndex), // แสดงหน้าอื่นๆ
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Course'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF004D6D), // สีน้ำเงินเข้ม
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Widget สำหรับเนื้อหาหน้า Home (ไม่มีการเปลี่ยนแปลงในส่วนนี้)
class _HomeContent extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _HomeContent({this.data});

  @override
  Widget build(BuildContext context) {
    final user = data?["user"] ?? {"name": "User", "learnedToday": 46, "goalMinutes": 60};
    final hotCourse = data?["hotCourse"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ส่วนสถานะการเรียน (Learned today)
        _buildLearningStatus(user),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Hot Course of the week",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D6D)),
          ),
        ),
        _buildHotCourseCard(hotCourse),

        // Calendar Section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Calendar",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        _buildCalendar(),

        // Booking Section
        _buildBookingSection(),

        // ข้อมูลอื่นๆ ที่มาจาก API เก่า
        if (data != null) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text("📘 Learning Plan (from API)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...List.from(data!["learningPlan"]).map((lp) => ListTile(
            title: Text(lp["title"]),
            subtitle: Text("Progress: ${lp["progress"]}"),
          )),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text("📢 Announcement (from API)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: Image.network(data!["announcement"]["bannerUrl"]),
              title: Text(data!["announcement"]["title"]),
              subtitle: Text(data!["announcement"]["subtitle"]),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  // Widgets ย่อย (LearningStatus, HotCourseCard, Calendar, BookingSection)
  // ... (โค้ดของ Widgets ย่อยเหล่านี้เหมือนเดิมจากคำตอบก่อนหน้า) ...

  Widget _buildLearningStatus(Map<String, dynamic> user) {
    final learned = user['learnedToday'];
    final goal = user['goalMinutes'];
    final progress = learned / goal;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Learned today", style: TextStyle(color: Colors.grey)),
                  Text("My courses", style: TextStyle(color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$learned min",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D6D),
                    ),
                  ),
                  Text("/ $goal min", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.blue.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotCourseCard(Map<String, dynamic>? hotCourse) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA), // สีฟ้าอ่อน
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/hot_course_illustration.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hotCourse?["title"] ?? "Hot Course of the week",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D6D)),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Start now", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 180,
            width: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Icon(Icons.check_circle, size: 40, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 16),
                const Text(
                  "April, 2025",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("Mo"),
                Text("Tu"),
                Text("We"),
                Text("Th"),
                Text("Fr"),
                Text("Sa"),
                Text("Su"),
              ],
            ),
            const Divider(),
            _buildDateRow([29, 30, 31, 1, 2, 3, 4], -1),
            _buildDateRow([5, 6, 7, 8, 9, 10, 11], 7),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(List<int> dates, int selectedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dates.map((date) {
          final isSelected = date == selectedDate;
          final isFaded = date > 20 && date < 32;

          return Container(
            width: 35,
            height: 35,
            decoration: isSelected
                ? BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            )
                : null,
            alignment: Alignment.center,
            child: Text(
              date.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : (isFaded ? Colors.grey : Colors.black),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Booking",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
              ),
            ),
            const Spacer(),
            Container(
              width: 100,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/booking_illustration.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
// ------------------------------------------------------------------
// Pages Dummy (ไม่มีการเปลี่ยนแปลง)
// ------------------------------------------------------------------

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Search Page Content"));
  }
}
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Message Page Content"));
  }
}
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Account Page Content"));
  }
}