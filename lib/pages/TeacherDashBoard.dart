import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'TeacherRequestBooking.dart';

// หน้าอื่น ๆ
import 'TeacherGradeBook.dart';
import 'TeacherProgress.dart';
import 'TeacherAccount.dart';

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TeacherDashboard({super.key, required this.userData});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {

  int _selectedIndex = 0;

  bool _isLoading = true;

  List<dynamic> _pendingClasses = [];
  List<dynamic> _waitingPaymentClasses = [];
  List<dynamic> _confirmedClasses = [];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const SizedBox(), // index 0 ไม่ใช้
      const TeacherGradeBook(),
      TeacherRequestBooking(
        teacherId: widget.userData['_id'],
      ),
      const TeacherProgress(),
      const TeacherAccount(),
    ];

    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {

    try {

      final teacherId = widget.userData['_id'];

      final data = await ApiService.getTeacherBookings(teacherId);

      setState(() {

        _pendingClasses =
            data.where((b) => b['status'] == 'pending').toList();

        _waitingPaymentClasses =
            data.where((b) => b['status'] == 'accepted').toList();

        _confirmedClasses =
            data.where((b) => b['status'] == 'completed').toList();

        _isLoading = false;

      });

    } catch (e) {

      setState(() => _isLoading = false);

    }
  }

  void _onTabTapped(int index) {

    setState(() {
      _selectedIndex = index;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: _selectedIndex == 0
          ? (_isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHome())
          : pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: _selectedIndex,

        onTap: _onTabTapped,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF0D4158),

        unselectedItemColor: Colors.grey,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Gradebook",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Booking",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Progress",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),

        ],
      ),
    );
  }

  Widget _buildHome() {

    final teacherName = widget.userData['name'] ?? "Teacher";

    return Stack(

      children: [

        Column(

          children: [

            _buildHeader(teacherName),

            Expanded(

              child: SingleChildScrollView(

                padding: const EdgeInsets.only(
                    top: 115,
                    left: 20,
                    right: 20),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Upcoming Events",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D214F)),
                    ),

                    const SizedBox(height: 15),

                    ...[
                      ..._waitingPaymentClasses,
                      ..._confirmedClasses
                    ].map((booking) =>
                        _buildEventItem(booking)).toList(),

                  ],
                ),
              ),
            ),

          ],
        ),

        Positioned(

          top: MediaQuery.of(context).size.height * 0.20,

          left: 0,
          right: 0,

          child: SingleChildScrollView(

            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Row(

              children: [

                GestureDetector(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherRequestBooking(
                                teacherId:
                                widget.userData['_id']),
                      ),

                    ).then((_) => _fetchDashboardData());

                  },

                  child: _buildStatCard(
                      "Pending",
                      "${_pendingClasses.length}",
                      const Color(0xFFF15F3E),
                      Icons.hourglass_empty),

                ),

                const SizedBox(width: 12),

                _buildStatCard(
                    "To Pay",
                    "${_waitingPaymentClasses.length}",
                    Colors.orange,
                    Icons.payment),

                const SizedBox(width: 12),

                _buildStatCard(
                    "Confirmed",
                    "${_confirmedClasses.length}",
                    const Color(0xFF2AB084),
                    Icons.check_circle),

              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildHeader(String name) {

    return Container(

      height: MediaQuery.of(context).size.height * 0.28,

      width: double.infinity,

      decoration: const BoxDecoration(

        color: Color(0xFFFFD54F),

        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30)),

      ),

      padding: const EdgeInsets.only(
          top: 50,
          left: 30,
          right: 20),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              const Text(
                "Hello ! Teacher",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white),
              ),

              Row(

                children: [

                  IconButton(
                    icon: const Icon(Icons.message,
                        color: Colors.white),
                    onPressed: () {},
                  ),

                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white),
                    onPressed: () =>
                        FirebaseAuth.instance.signOut(),
                  ),

                ],
              )

            ],
          ),

          Text(
            name,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),

        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String count,
      Color color,
      IconData icon) {

    return Container(

      width: 130,

      padding: const EdgeInsets.symmetric(vertical: 18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10)
        ],

      ),

      child: Column(

        children: [

          Icon(icon, color: color),

          const SizedBox(height: 6),

          Text(title,
              style: const TextStyle(color: Colors.grey)),

          Text(count,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),

        ],
      ),
    );
  }

  Widget _buildEventItem(dynamic booking) {

    bool isPaid = booking['status'] == 'completed';

    Color statusColor =
    isPaid ? const Color(0xFF2AB084) : Colors.orange;

    return ListTile(

      leading: Icon(
          isPaid ? Icons.check_circle : Icons.access_time,
          color: statusColor),

      title: Text(
        booking['course_name'] ?? "Course",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle: Text(
          "${booking['booking_date']}\n${booking['booking_time']}"),

    );
  }
}