import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/course.model.dart';
import '../model/class_schedule.model.dart';
import '../services/api_service.dart';

class BookingPage extends StatefulWidget {
  final CourseModel course;

  const BookingPage({
    super.key,
    required this.course,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = true;

  List<ClassSchedule> _schedules = [];

  DateTime? _selectedDate;
  ClassSchedule? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _loadSchedules();

  }
  Future<void> _loadSchedules() async {
    try {
      print('🔵 START load schedules');
      print('courseId = ${widget.course.id}');

      final data =
      await ApiService.getClassSchedulesByCourse(widget.course.id);

      print('✅ schedules length = ${data.length}');
      for (var s in data) {
        print('📅 ${s.date} ${s.startTime}-${s.endTime}');
      }

      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() => _isLoading = false);
    }
  }


  // ==============================
  // เช็คว่าวันนี้มีสอนจริงไหม
  // ==============================
  bool _isAvailableDay(DateTime day) {
    return _schedules.any((s) {
      final d = DateTime.parse(s.date);
      return d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    });
  }

  // ==============================
  // ตารางเรียนของวันที่เลือก
  // ==============================
  List<ClassSchedule> _getSchedulesOfSelectedDate() {
    if (_selectedDate == null) return [];

    return _schedules.where((s) {
      final d = DateTime.parse(s.date);
      return d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==============================
            // ข้อมูลวิชา + อาจารย์
            // ==============================
            Text(
              widget.course.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text('ผู้สอน: ${widget.course.instructor}'),

            const SizedBox(height: 16),

            // ==============================
            // Calendar (เลือกได้เฉพาะวันมีสอน)
            // ==============================
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate ?? DateTime.now(),

              enabledDayPredicate: _isAvailableDay,

              selectedDayPredicate: (day) =>
              _selectedDate != null &&
                  day.year == _selectedDate!.year &&
                  day.month == _selectedDate!.month &&
                  day.day == _selectedDate!.day,

              onDaySelected: (day, _) {
                setState(() {
                  _selectedDate = day;
                  _selectedSchedule = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // ==============================
            // เลือกช่วงเวลา
            // ==============================
            DropdownButton<ClassSchedule>(
              isExpanded: true,
              hint: const Text('เลือกเวลาเรียน'),
              value: _selectedSchedule,
              items: _getSchedulesOfSelectedDate()
                  .map(
                    (s) => DropdownMenuItem(
                  value: s,
                  child: Text('${s.startTime} - ${s.endTime}'),
                ),
              )
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedSchedule = val);
              },
            ),

            const Spacer(),

            // ==============================
            // Next
            // ==============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSchedule == null
                    ? null
                    : () async {
                  try {
                    await ApiService.createBooking(
                      courseId: widget.course.id,
                      scheduleId: _selectedSchedule!.id,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('จองเรียนสำเร็จ'),
                      ),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('จองไม่สำเร็จ'),
                      ),
                    );
                  }
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
