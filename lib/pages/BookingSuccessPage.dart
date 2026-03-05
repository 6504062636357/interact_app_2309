import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/course.model.dart';

class BookingSuccessPage extends StatelessWidget {
  final CourseModel course;
  final dynamic instructor;
  final DateTime selectedDate;
  final String selectedTime;

  const BookingSuccessPage({
    super.key,
    required this.course,
    required this.instructor,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D6D), // พื้นหลังสีน้ำเงินเข้มตามธีม
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Booking",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Icon(Icons.chat_bubble, color: Colors.white),
                ],
              ),
            ),

            // Success Card
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.orange, size: 80), // ไอคอนสำเร็จ
                      const SizedBox(height: 15),
                      const Text(
                        "Booking Confirmed!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF004D6D)),
                      ),
                      const SizedBox(height: 30),

                      // ส่วนข้อมูลผู้สอน
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(instructor['imageUrl'] ?? 'https://via.placeholder.com/150'),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        instructor['name'] ?? 'Instructor',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        instructor['specialty'] ?? 'Expert',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 30),

                      // รายละเอียดคอร์สและเวลา
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF004D6D)),
                                const SizedBox(width: 10),
                                Text(
                                  "${DateFormat('EEEE, MMM d').format(selectedDate)}  •  $selectedTime",
                                  style: const TextStyle(color: Colors.blueGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ปุ่มการทำงาน
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {}, // เพิ่มลงปฏิทินมือถือ
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF4D1),
                            foregroundColor: Colors.orange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("Add to calendar", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("View Booking", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}