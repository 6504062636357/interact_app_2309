import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Import pages
import 'Account.dart';
import 'Course.dart';
import 'profile_page.dart';
import 'Message.dart';
import 'Search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _futureDashboard;
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    Container(),
    const CoursePage(),
    const SearchPage(),
    const MessagePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _futureDashboard = ApiService.getDashboard();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(String userName) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF004D6D),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, $userName",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Let's start learning",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LEARN TODAY CARD ----------------
  Widget _buildLearningStatus(Map<String, dynamic> user) {
    final learned = user['learnedToday'];
    final goal = user['goalMinutes'];
    final progress = goal == 0 ? 0.0 : learned / goal;

    return Card(
      elevation: 12,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              children: [
                Text(
                  "$learned min",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D6D),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "/ $goal min",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? FutureBuilder<Map<String, dynamic>>(
        future: _futureDashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final user = data["user"] ??
              {"name": "User", "learnedToday": 0, "goalMinutes": 0};

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  _buildHeader(user['name']),

                  // CARD (ขยับขึ้นให้เหมือนลอย)
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildLearningStatus(user),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BODY
                  _buildHomeBody(data),
                ],
              ),
            ),
          );
        },
      )
          : _widgetOptions[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004D6D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Course'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
// ---------------- BODY ----------------
  Widget _buildHomeBody(Map<String, dynamic>? data) {
    final hotCourse = data?["hotCourse"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Hot Course of the week",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D6D),
            ),
          ),
        ),

        _buildHotCourseCard(hotCourse),

        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Calendar",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        _buildCalendar(),
        _buildBookingSection(),

        const SizedBox(height: 40),
      ],
    );
  }
}


  // ---------------- OTHER SECTIONS ----------------
  Widget _buildHotCourseCard(Map<String, dynamic>? hotCourse) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hotCourse?["title"] ?? "Coding Story (Python)",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D6D),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Start now"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 180,
            width: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("Calendar UI")),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "Booking",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }


// ---------------- DUMMY PAGES ----------------
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Message Page Content"));
}

// class AccountPage extends StatelessWidget {
//   const AccountPage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text("Account Page Content"));
//   }
// }
