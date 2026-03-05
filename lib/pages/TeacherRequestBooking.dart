import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // อย่าลืมลง package นี้นะครับ
import '../services/api_service.dart';

class TeacherRequestBooking extends StatefulWidget {
  final String teacherId;
  const TeacherRequestBooking({super.key, required this.teacherId});

  @override
  State<TeacherRequestBooking> createState() => _TeacherRequestBookingState();
}

class _TeacherRequestBookingState extends State<TeacherRequestBooking> {
  bool _isLoading = true;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _confirmedBookings = []; // สำหรับโชว์ในปฏิทิน
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _selectedDay = _focusedDay;
  }

  Future<void> _fetchRequests() async {
    try {
      final data = await ApiService.getTeacherBookings(widget.teacherId);
      setState(() {
        _pendingRequests = data.where((b) => b['status'] == 'pending').toList();
        _confirmedBookings = data.where((b) => b['status'] == 'accepted' || b['status'] == 'completed').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching requests: $e");
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateBookingStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully $status request")),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFD54F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0D214F)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Management",
            style: TextStyle(color: Color(0xFF0D214F), fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF0D214F),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF0D214F),
            tabs: [
              Tab(text: "Booking"),
              Tab(text: "Schedule"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildBookingTab(),
            _buildScheduleTab(),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Booking Management ---
  Widget _buildBookingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Pending Requests",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D214F)),
          ),
        ),
        Expanded(
          child: _pendingRequests.isEmpty
              ? const Center(child: Text("No pending requests found."))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _pendingRequests.length,
            itemBuilder: (context, index) => _buildRequestCard(_pendingRequests[index]),
          ),
        ),
      ],
    );
  }

  // --- Tab 2: Schedule & Calendar ---
  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- ภายใน Widget _buildScheduleTab() ---
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            // ✅ เพิ่ม calendarBuilders เพื่อวาดจุดสีส้มใต้เลขวัน
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                // เช็คว่าวันนั้นมีการจองที่สถานะเป็น 'accepted' (Wait to Pay) หรือไม่
                bool hasWaitPay = _confirmedBookings.any((b) {
                  DateTime bookingDate = DateTime.parse(b['booking_date']);
                  return isSameDay(bookingDate, day) && b['status'] == 'accepted';
                });

                if (hasWaitPay) {
                  return Positioned(
                    bottom: 4, // ระยะห่างจากขอบล่างของช่องวันที่
                    child: Container(
                      width: 6, // ขนาดจุดวงกลมสีส้มตัวเล็กๆ
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.orange, // สีส้ม Wait Pay
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Color(0xFFFFD54F), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF0D214F), shape: BoxShape.circle),
              markersAlignment: Alignment.bottomCenter, // จัดตำแหน่งจุดให้อยู่กึ่งกลางด้านล่าง
            ),
          ),
          const Divider(),
          _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    // กรองข้อมูลเฉพาะวันที่เลือกในปฏิทิน
    final dayBookings = _confirmedBookings.where((b) {
      DateTime bookingDate = DateTime.parse(b['booking_date']);
      return isSameDay(bookingDate, _selectedDay);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text("Today's Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (dayBookings.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No classes today.")))
        else
          ...dayBookings.map((b) => _buildScheduleItem(b)).toList(),
      ],
    );
  }

  Widget _buildScheduleItem(dynamic booking) {
    bool isWaitPay = booking['status'] == 'accepted';

    return ListTile(
      leading: Icon(isWaitPay ? Icons.access_time : Icons.check_circle,
          color: isWaitPay ? Colors.orange : const Color(0xFF2AB084)),
      title: Text(booking['course_name'] ?? "Course"),
      subtitle: Text(booking['booking_time']),
      trailing: isWaitPay
          ? Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
      ) // วงกลมส้มเล็กๆ สำหรับ Wait Pay
          : const Icon(Icons.check, color: Color(0xFF2AB084), size: 16),
    );
  }

  Widget _buildRequestCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(booking['student_name'] ?? "Student", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Course: ${booking['course_name']}\n${booking['booking_date']} | ${booking['booking_time']}"),
            ),
            const Divider(),
            _buildActionButtons(booking['_id']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String bookingId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _updateStatus(bookingId, 'rejected'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Decline"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateStatus(bookingId, 'accepted'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AB084)),
            child: const Text("Accept", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}