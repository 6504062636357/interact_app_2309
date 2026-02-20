import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/course.model.dart';
import '../model/class_schedule.model.dart';
import '../services/api_service.dart';

class BookingPage extends StatefulWidget {
  final CourseModel course;

  const BookingPage({super.key, required this.course});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = true;
  bool _isBookmarked = false;

  List<ClassSchedule> _schedules = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  ClassSchedule? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.course.isBookmarked;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final data =
      await ApiService.getClassSchedulesByCourse(widget.course.id);

      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ กัน date null + format พัง
  bool _isAvailableDay(DateTime day) {
    return _schedules.any((s) {
      final d = DateTime.tryParse(s.date);
      if (d == null) return false;
      return isSameDay(d, day);
    });
  }

  /// ✅ กัน null
  List<ClassSchedule> _getSchedulesOfSelectedDate() {
    if (_selectedDate == null) return [];

    return _schedules.where((s) {
      final d = DateTime.tryParse(s.date);
      if (d == null) return false;
      return isSameDay(d, _selectedDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print("IMAGE URL => ${widget.course.instructorImage}");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4C20D),
        elevation: 0,
        title: const Text("Booking",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// ================= Instructor =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.course.instructorImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                        ),
                      ),

                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.course.instructor,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < widget.course.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 18,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          setState(() => _isBookmarked = !_isBookmarked),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ================= Calendar =================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 90)),
                  focusedDay: _focusedDay,

                  /// ✅ FIX ERROR ตรงนี้
                  selectedDayPredicate: (day) =>
                  _selectedDate != null && isSameDay(day, _selectedDate),

                  enabledDayPredicate: _isAvailableDay,

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedSchedule = null;
                    });
                  },

                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF0D5C75),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= Time =================
              DropdownButtonFormField<ClassSchedule>(
                value: _selectedSchedule,
                hint: const Text("เลือกเวลาเรียน"),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEDEFF5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _getSchedulesOfSelectedDate()
                    .map(
                      (s) => DropdownMenuItem(
                    value: s,
                    child: Text("${s.startTime} - ${s.endTime}"),
                  ),
                )
                    .toList(),
                onChanged: (val) => setState(() => _selectedSchedule = val),
              ),

              const SizedBox(height: 30),

              /// ================= Button =================
              SizedBox(
                width: 160,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5C75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _selectedSchedule == null
                      ? null
                      : () async {
                    await ApiService.createBooking(
                      courseId: widget.course.id,
                      scheduleId: _selectedSchedule!.id,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Next"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
