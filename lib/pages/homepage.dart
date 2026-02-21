import 'package:flutter/material.dart';
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
  int _selectedIndex = 0;

  List<Widget> get _pages => const [
    _HomeDashboardMock(), // Home UI แบบในภาพ (mock data)
    CoursePage(),
    SearchPage(),
    MessagePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF004D6D),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Course"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Message"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

class _HomeDashboardMock extends StatelessWidget {
  const _HomeDashboardMock();

  @override
  Widget build(BuildContext context) {
    // mock data ให้เหมือนภาพ
    const userName = "Kristina";
    const learnedToday = 46;
    const goalMinutes = 60;
    final progress = (goalMinutes == 0) ? 0.0 : learnedToday / goalMinutes;

    return SafeArea(
      child: Stack(
        children: [
          // พื้นหลัง header สีฟ้า
          Container(
            height: 240,
            width: double.infinity,
            color: const Color(0xFF004D6D),
          ),

          // เนื้อหาเลื่อน
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header text
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 6),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, $userName",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Let's start learning",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // card "Learned today" ซ้อนทับ header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _LearnedTodayCard(
                    learnedToday: learnedToday,
                    goalMinutes: goalMinutes,
                    progress: progress.clamp(0.0, 1.0),
                  ),
                ),

                const SizedBox(height: 18),

                // Hot course row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Expanded(child: _HotCourseCard()),
                      SizedBox(width: 12),
                      _SideStatusCard(),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Calendar",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _CalendarCard(),
                ),

                const SizedBox(height: 18),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _BookingCard(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnedTodayCard extends StatelessWidget {
  final int learnedToday;
  final int goalMinutes;
  final double progress;

  const _LearnedTodayCard({
    required this.learnedToday,
    required this.goalMinutes,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Text("Learned today", style: TextStyle(color: Colors.grey)),
              Spacer(),
              Text("My courses", style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${learnedToday}min",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D6D),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "/ ${goalMinutes}min",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotCourseCard extends StatelessWidget {
  const _HotCourseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hot Course\nof the week",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2C3A),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Start now", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideStatusCard extends StatelessWidget {
  const _SideStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(Icons.check_circle, size: 44, color: Colors.green),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleIcon(Icons.chevron_left),
              const Spacer(),
              const Text("April 2025", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              _circleIcon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text("Mo"), Text("Tu"), Text("We"), Text("Th"), Text("Fr"), Text("Sa"), Text("Su"),
            ],
          ),
          const SizedBox(height: 10),
          _dateRow([29, 30, 31, 1, 2, 3, 4], selected: -1),
          const SizedBox(height: 8),
          _dateRow([5, 6, 7, 8, 9, 10, 11], selected: 7),
        ],
      ),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.grey.shade700),
    );
  }

  static Widget _dateRow(List<int> dates, {required int selected}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dates.map((d) {
        final isSelected = d == selected;
        final isFaded = d >= 29; // 29-31 ของเดือนก่อน
        return Container(
          width: 36,
          height: 36,
          decoration: isSelected
              ? BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10))
              : null,
          alignment: Alignment.center,
          child: Text(
            d.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : (isFaded ? Colors.grey : Colors.black),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Text(
            "Booking",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),
          Spacer(),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.people, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// Dummy pages
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Search Page Content"));
}

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Message Page Content"));
}


