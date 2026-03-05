import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';

class TeacherCalendarPage extends StatefulWidget {
  final Map<String, dynamic> userData; // รับข้อมูลครูจาก Dashboard

  const TeacherCalendarPage({super.key, required this.userData});

  @override
  State<TeacherCalendarPage> createState() => _TeacherCalendarPageState();
}

class _TeacherCalendarPageState extends State<TeacherCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // โครงสร้างข้อมูล slots ตามที่คุณต้องการ
  List<Map<String, dynamic>> _availabilitySlots = [
    {"time": "09:00-10:00", "isBooked": false, "currentBookings": 0},
    {"time": "10:00-11:00", "isBooked": false, "currentBookings": 0},
    {"time": "13:00-14:00", "isBooked": false, "currentBookings": 0},
  ];

  // ฟังก์ชันบันทึกข้อมูลลง MongoDB
  Future<void> _saveToDatabase() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกวันที่ก่อนบันทึก")),
      );
      return;
    }

    final data = {
      "instructorId": widget.userData['_id'], // ดึง ID จาก MongoDB
      "instructorName": widget.userData['name'], // ดึงชื่อครู
      "courseId": "68d198af7c5c95e4d7cebea6", // ID วิชา Coding Story (Python)
      "courseTitle": "Coding Story (Python)", // ชื่อวิชา
      "date": _selectedDay!.toIso8601String(), // วันที่ที่เลือก
      "maxStudents": 5, // จำนวนรับสูงสุดต่อรอบ
      "slots": _availabilitySlots, // รายการเวลา
    };

    try {
      // เรียกใช้ ApiService เพื่อส่งข้อมูล (ต้องไปสร้างฟังก์ชันนี้ใน ApiService ด้วย)
      final response = await ApiService.saveTeacherAvailability(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกวันว่างสำเร็จแล้ว!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("จัดการวันว่าง")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _availabilitySlots.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(_availabilitySlots[index]['time']),
                  subtitle: Text("จองแล้ว: ${_availabilitySlots[index]['currentBookings']} / 5 คน"), // แสดงจำนวนคนจอง
                  trailing: Checkbox(
                    value: !_availabilitySlots[index]['isBooked'],
                    onChanged: (val) {
                      setState(() {
                        // จำลองการเปิด-ปิดสถานะว่าง
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveToDatabase,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              child: const Text("ยืนยันวันว่างลง Database", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}