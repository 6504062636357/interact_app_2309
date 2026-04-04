import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../model/course.model.dart';
import '../services/api_service.dart';
import 'BookingSuccessPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  final CourseModel course;
  final String? paymentId;
  const BookingPage({
    super.key,
    required this.course,
   this.paymentId //ตัวแปรที่ส่งสถานะการชำระเงินไปให้ booking ดูว่าชำระเงินเรียบร้อยยัง
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = true;
  List<dynamic> _instructors = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _selectedTime;
  String? _selectedInstructorId;

  @override
  void initState() {
    super.initState();
    print("DEBUG: Booking Page received ID -> ${widget.paymentId}");
    _selectedDay = _focusedDay;
    _loadData();
  }

  // ใน _BookingPageState
  Future<void> _loadData() async {
    try {
      // แทนที่จะดึงทุกคน ให้ดึงคนที่มีชื่อตรงกับใน widget.course.instructor
      final instructor = await ApiService.getInstructorByName(widget.course.instructor);

      setState(() {
        if (instructor != null) {
          _instructors = [instructor]; // แสดงแค่ครูที่สอนวิชานี้จริง
          _selectedInstructorId = instructor['_id']; // ล็อก ID ครู
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF004D6D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCourseInfoCard(),
                      const SizedBox(height: 25),
                      const Text(
                        "Select a Date",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _buildCalendar(),
                      const SizedBox(height: 15),
                      Text(
                        _selectedDay != null
                            ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
                            : "Select a date",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Select a Time",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildTimeSlots(),
                      const SizedBox(height: 25),
                      const Text(
                        "Select an Instructor",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      _buildInstructorList(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      // ✅ key ใช้ _selectedDay เพื่อบังคับ redraw ทุกครั้งที่เลือกวันใหม่
      key: ValueKey(_selectedDay),
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2026, 12, 31),
      focusedDay: _focusedDay,

      selectedDayPredicate: (day) {
        if (_selectedDay == null) return false;
        return isSameDay(day, _selectedDay);
      },

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _selectedTime = null;
        });
      },

      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },

      calendarStyle: CalendarStyle(
        // ✅ แก้ปัญหาหลัก: today ต้องไม่ทับ selected
        isTodayHighlighted: true,
        todayDecoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildTimeSlots() {
    // แก้ไขเป็นช่วงเวลาตามที่คุณต้องการ
    List<String> times = [
      "10:00 AM - 12:00 PM",
      "11:00 AM - 01:00 PM",
      "02:00 PM - 04:00 PM",
      "04:00 PM - 06:00 PM"
    ];

    return Wrap(
      spacing: 12,
      children: times.map((time) {
        bool isSelected = _selectedTime == time;
        return ChoiceChip(
          label: Text(time, style: TextStyle(fontSize: 12)), // ปรับขนาดฟอนต์ให้เล็กลงนิดนึงเพราะข้อความยาวขึ้น
          selected: isSelected,
          onSelected: (val) => setState(() => _selectedTime = val ? time : null),
          selectedColor: const Color(0xFFFFEEDD),
          labelStyle: TextStyle(
            color: isSelected ? Colors.orange : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildInstructorList() {
    return Column(
      children: _instructors.map((instructor) {
        // ✅ ตรวจสอบ ID ให้ตรงกับฟิลด์ใน MongoDB (ปกติคือ '_id')
        bool isSelected = _selectedInstructorId == instructor['_id'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedInstructorId = instructor['_id'];
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ✅ เปลี่ยนสีพื้นหลังเมื่อเลือกเหมือนในดีไซน์
              color: isSelected ? const Color(0xFFFFF9E5) : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(15),
              border: isSelected ? Border.all(color: Colors.orange.withOpacity(0.5)) : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    instructor['imageUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor['name'] ?? 'Instructor',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      instructor['specialty'] ?? 'Expert',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                // ✅ แสดงเครื่องหมายถูกเมื่อเลือก
                if (isSelected) const Icon(Icons.check_circle, color: Colors.cyan),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              widget.course.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.course.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "Total ${widget.course.durationHours} hours",
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              const Icon(Icons.star, color: Colors.orange, size: 18),
              Text(
                " ${widget.course.rating}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Booking",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text("Let's start learning",
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          Icon(Icons.chat_bubble, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                print("DEBUG 4: Final Payment ID in BookingPage -> ${widget.paymentId}");
                if (_selectedDay != null && _selectedTime != null && _selectedInstructorId != null) {

                  setState(() => _isLoading = true); // เริ่มโหลด

                  try {
                    // 1. ดึง authUid จาก Firebase
                    final String? authUid = FirebaseAuth.instance.currentUser?.uid;
                    if (authUid == null) throw Exception("Please login first");

                    // 2. เตรียม Data ให้ตรงกับ API ที่เราแก้ใน server.js
                    final Map<String, dynamic> bookingData = {
                      "authUid": authUid,
                      "course_id": widget.course.id, // ตรวจสอบว่าใน CourseModel ใช้ฟิลด์ id
                      "instructor_id": _selectedInstructorId,
                      "booking_date": DateFormat('yyyy-MM-dd').format(_selectedDay!),
                      "booking_time": _selectedTime, // ส่งค่าเช่น "10:00 AM - 12:00 PM"
                      "payment_id": widget.paymentId,
                    };

                    // 3. เรียก API ส่งข้อมูลไป Backend
                    final response = await ApiService.createBooking(bookingData);

                    if (mounted) {
                      final selectedInstructor = _instructors.firstWhere(
                              (inst) => inst['_id'] == _selectedInstructorId
                      );

                      // 4. เมื่อสำเร็จ ไปหน้า Success
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingSuccessPage(
                            course: widget.course,
                            instructor: selectedInstructor,
                            selectedDate: _selectedDay!,
                            selectedTime: _selectedTime!,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select date, time, and instructor")),
                  );
                }
              },
              child: const Text(
                "Confirm Booking",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}