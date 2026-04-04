import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Import pages
import 'Account.dart';
import 'Course.dart';
import 'profile_page.dart';
import 'Message.dart';
import 'MainBookingPage.dart';
import 'ProgressStudent.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>>? _futureDashboard;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _futureDashboard = ApiService.getDashboard();
      });
    });
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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

          // MESSAGE BUTTON
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagePage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.messenger_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LEARNING CARD ----------------
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
              value: progress.toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.blue.shade100,
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ย้ายมาไว้ใน build เพื่อให้ rebuild ทุกครั้ง
    final List<Widget> widgetOptions = [
      Container(), // index 0 = Home (handled by FutureBuilder below)
      const CoursePage(),        // index 1
      const MainBookingPage(),   // index 2
      const ProgressStudent(),   // index 3 ✅
      const ProfilePage(),       // index 4
    ];

    return Scaffold(
      body: _selectedIndex == 0
          ? FutureBuilder<Map<String, dynamic>>(
        future: _futureDashboard ?? ApiService.getDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final user = data["user"] ?? {
            "name": "User",
            "learnedToday": 0,
            "goalMinutes": 0
          };

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user['name']),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildLearningStatus(user),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHomeBody(data),
                ],
              ),
            ),
          );
        },
      )
          : widgetOptions[_selectedIndex], // ✅ ใช้ local list

      // ---------------- BOTTOM BAR ----------------
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF004D6D),
          unselectedItemColor: Colors.blueGrey.shade300,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: 'Course'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Progress'), // index 3 ✅
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    );
  }

  // ---------------- BODY ----------------
  Widget _buildHomeBody(Map<String, dynamic>? data) {
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
        const SizedBox(height: 20),
        _buildCalendar(),
        _buildBookingSection(),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
}