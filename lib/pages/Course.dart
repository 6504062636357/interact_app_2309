import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

import '../model/course.model.dart';
import '../services/api_service.dart';
import 'tabs/myclass_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/Booking_tab.dart';
import '../model/course.model.dart';
import '../services/api_service.dart';
import 'CourseDetail.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  // ================= DATA STATE =================
  List<CourseModel> _allCourses = []; // เริ่มต้นเป็น List ว่าง ไม่ใช่ null
  bool _isLoading = true;
  int _tabIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  // ================= FILTER STATE =================
  String _selectedCategory = 'All';
  String _selectedSort = 'All';
  RangeValues _priceRange = const RangeValues(0, 25000);

  @override
  void initState() {
    super.initState();
    _fetchCoursesWithFilter();

    _searchCtrl.addListener(() {
      _fetchCoursesWithFilter();
    });
  }

  // แก้ไข: ฟังก์ชันสำหรับเลือก Tab ที่จะแสดงผลแบบปลอดภัย
  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A68FF)));
    }

    switch (_tabIndex) {
      case 0:
      // ตรวจสอบความปลอดภัยก่อนส่งข้อมูล
        return MyClassTab(courses: _allCourses);
      case 1:
        return const CalendarTab();
      case 2:
        return const BookingTab();
      default:
        return const SizedBox();
    }
  }

  Future<void> _fetchCoursesWithFilter() async {
    try {
      String? categoryParam = (_selectedCategory == 'All') ? null : _selectedCategory;
      String? sortParam = (_selectedSort == 'All') ? null : _selectedSort.toLowerCase();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final courseData = await ApiService.getCourses(
        category: categoryParam,
        sort: sortParam,
        search: _searchCtrl.text,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      );

      if (mounted) {
        setState(() {
          // ตรวจสอบว่าข้อมูลที่ได้มาไม่เป็น null ก่อน map
          _allCourses = courseData != null
              ? courseData.map((json) => CourseModel.fromJson(json)).toList()
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allCourses = []; // ถ้าพังให้เป็น List ว่าง
          _isLoading = false;
        });
      }
      debugPrint("API Error: $e");
    }
  }

  // --- [ ส่วนของ UI BottomSheet และ UI อื่นๆ คงเดิมตามโค้ดต้นฉบับของคุณ ] ---
  void _showFilterBottomSheet() {
    OnscreenKeyboard.of(context).close();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("Search Filter", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Maths', 'Robotic', 'Science', 'Language'].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (v) => setModalState(() => _selectedCategory = v ? cat : 'All'),
                          selectedColor: const Color(0xFF4A68FF),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    const Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 25000,
                      activeColor: const Color(0xFF4A68FF),
                      onChanged: (val) => setModalState(() => _priceRange = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("\$${_priceRange.start.toInt()}", style: const TextStyle(color: Colors.grey)),
                        Text("\$${_priceRange.end.toInt()}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("Duration", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['3-8 Hours', '8-14 Hours', '14-20 Hours'].map((dur) {
                        bool isSel = _selectedDuration == dur;
                        return ChoiceChip(
                          label: Text(dur),
                          selected: isSel,
                          onSelected: (v) => setModalState(() => _selectedDuration = v ? dur : null),
                          selectedColor: const Color(0xFF4A68FF),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _priceRange = const RangeValues(0, 25000);
                          });
                          Navigator.pop(context);
                          _fetchCoursesWithFilter();
                        },
                        child: const Text("Clear"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A68FF)),
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchCoursesWithFilter();
                        },
                        child: const Text("Apply Filter", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => OnscreenKeyboard.of(context).close(),
          child: Column(
            children: [
              // HEADER (My Class + Search + Category Cards)
              Container(
                color: const Color(0xFFFFD338),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Class', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: OnscreenKeyboardTextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Find Course',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterBottomSheet),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _categoryCard('Maths', const Color(0xFFE3F2FD), Colors.blue, Icons.calculate),
                        const SizedBox(width: 12),
                        _categoryCard('Robotic', const Color(0xFFF3E5F5), Colors.purple, Icons.smart_toy),
                      ],
                    ),
                  ],
                ),
              ),

              // TAB BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _tabBtn('Class', 0),
                    _tabBtn('Calendar', 1),
                    _tabBtn('Booking', 2),
                  ],
                ),
              ),

              // CONTENT AREA (เรียกใช้ฟังก์ชันที่เช็ก Null แล้ว)
              Expanded(
                child: _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Helpers (คงเดิม) ---
  Widget _categoryCard(String title, Color bg, Color textCol, IconData icon) {
    final bool isSel = _selectedCategory == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = isSel ? 'All' : title);
          _fetchCoursesWithFilter();
        },
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: isSel ? Border.all(color: textCol, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textCol, size: 32),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String title, int index) {
    final selected = _tabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
