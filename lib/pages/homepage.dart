import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _futureDashboard = ApiService.getDashboard());
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  String _resolveDisplayName(Map<String, dynamic> apiUser) {
    final candidates = [
      apiUser['name'],
      apiUser['displayName'],
      widget.userData['name'],
      widget.userData['displayName'],
    ];
    for (final c in candidates) {
      if (c != null &&
          c.toString().trim().isNotEmpty &&
          !c.toString().contains('@')) {
        return c.toString().trim();
      }
    }
    return 'there';
  }

  // ── Header ──
  Widget _buildHeader(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002D42), Color(0xFF005F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $userName 👋",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Let's start learning",
                style: TextStyle(fontSize: 15, color: Colors.white60),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessagePage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.2),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Learning Card ──
  Widget _buildLearningCard(Map<String, dynamic> user) {
    final learned = (user['learnedToday'] ?? 0) as num;
    final goal = (user['goalMinutes'] ?? 60) as num;
    final progress = goal == 0 ? 0.0 : (learned / goal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_fire_department_rounded,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 5),
                  Text("Learned today",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("My courses",
                      style: TextStyle(
                          color: Color(0xFF004D6D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${learned.toInt()}",
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D6D),
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(" min",
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF004D6D),
                        fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Text("$percent%",
                  style: TextStyle(
                      fontSize: 13,
                      color: progress >= 1.0
                          ? Colors.green
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold)),
              Text(" / ${goal.toInt()} min",
                  style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8F4F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotCourseBanner() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFBEDEF0),
              Color(0xFFD6EEF8),
              Color(0xFFEAF5FB),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Row(
            children: [

              // ── รูปขวา ──
              Expanded(
                flex: 5,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Image(
                    image: const AssetImage('assets/HotCourse.png'),
                    height: 160,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Calendar ──
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    color: Color(0xFF004D6D), size: 20),
                SizedBox(width: 8),
                Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D6D),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            rowHeight: 44,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D6D),
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: Color(0xFF004D6D)),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF004D6D)),
              headerPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF004D6D).withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF004D6D),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              todayTextStyle: const TextStyle(
                color: Color(0xFF004D6D),
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(fontSize: 14),
              cellMargin: const EdgeInsets.all(4),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF004D6D),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              weekendStyle: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Booking Banner ──
  Widget _buildBookingBanner() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 2),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFFE57F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [

                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 130,
                    child: Image(
                      image: const AssetImage('assets/booking.png'),
                      fit: BoxFit.fitHeight,  // ← เปลี่ยนตรงนี้
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SizedBox.shrink(),
      const CoursePage(),
      const MainBookingPage(),
      const ProgressStudent(),
      const EditProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _selectedIndex == 0
          ? FutureBuilder<Map<String, dynamic>>(
        future: _futureDashboard ?? ApiService.getDashboard(),
        builder: (context, snapshot) {
          final fallbackName = _resolveDisplayName({});

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                _buildHeader(fallbackName),
                const Expanded(
                    child:
                    Center(child: CircularProgressIndicator())),
              ],
            );
          }

          final data = snapshot.data ?? {};
          final apiUser =
              (data['user'] as Map<String, dynamic>?) ?? {};
          final displayName = _resolveDisplayName(apiUser);

          final enrichedUser = {
            'learnedToday': 0,
            'goalMinutes': 60,
            ...apiUser,
            'name': displayName,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: _buildLearningCard(enrichedUser),
                ),
                _buildHotCourseBanner(),
                _buildCalendar(),
                _buildBookingBanner(),
              ],
            ),
          );
        },
      )
          : pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08), blurRadius: 14),
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
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded), label: 'Course'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded),
                label: 'Booking'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Account'),
          ],
        ),
      ),
    );
  }
}