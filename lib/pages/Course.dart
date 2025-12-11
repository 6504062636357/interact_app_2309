import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../model/course.model.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  // State Variables
  List<CourseModel> _allCourses = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String _selectedSort = 'All';
  String _searchText = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // ******************************************************
  // 1. DATA FETCHING LOGIC (เหมือนเดิม)
  // ******************************************************
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final categories = await ApiService.getCourseCategories();
      final courseData = await ApiService.getCourses();
      final courses = courseData.map((json) => CourseModel.fromJson(json)).toList();

      setState(() {
        _categories = ['All', ...categories];
        _allCourses = courses;
        _isLoading = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = 'All';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchCoursesWithFilter() async {
    setState(() => _isLoading = true);
    try {
      String? categoryParam = _selectedCategory == 'All' ? null : _selectedCategory;
      String? sortParam = _selectedSort == 'All' ? null : _selectedSort.toLowerCase();
      String? searchParam = _searchText.isEmpty ? null : _searchText;

      final courseData = await ApiService.getCourses(
        category: categoryParam,
        sort: sortParam,
        search: searchParam,
      );
      final courses = courseData.map((json) => CourseModel.fromJson(json)).toList();

      setState(() {
        _allCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load courses: ${e.toString()}';
      });
    }
  }

  // ******************************************************
  // 2. UI BUILD METHODS (ปรับปรุงดีไซน์)
  // ******************************************************

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // พื้นหลังสีเทาอ่อนเพื่อให้ Card เด่นขึ้น
      body: CustomScrollView(
        slivers: [
          // 2.1 Header สีเหลือง + Search Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 180.0,
            backgroundColor: const Color(0xFFFFC107), // สีเหลือง Amber
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 60), // ขยับ Title ขึ้นหนี SearchBar
              title: const Text(
                'Course',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 28),
              ),
              background: Stack(
                children: [
                  Container(color: const Color(0xFFFFC107)), // พื้นหลังสีเหลือง
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // โค้งรับกับ Body ด้านล่าง
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10, // ตำแหน่ง Search Bar กึ่งกลางรอยต่อ
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10), // เว้นระยะจาก SearchBar

                // 2.2 Category Filter (แบบ Card ใหญ่มีไอคอน)
                if (_categories.isNotEmpty) ...[
                  _buildCategoryFilter(),
                ],

                const SizedBox(height: 20),

                // 2.3 Title "Choice your course"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choice your course',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      TextButton(onPressed: (){}, child: const Text("See all"))
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2.4 Sort Chips (All, Popular, New)
                _buildSortFilter(),

                const SizedBox(height: 10),

                // 2.5 Course List Result
                _buildCourseListResult(),

                const SizedBox(height: 80), // เผื่อพื้นที่ให้ BottomNav
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ปรับปรุง Search Bar ให้โค้งมนและมีเงา ---
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => _searchText = value,
        onSubmitted: (value) => _fetchCoursesWithFilter(),
        decoration: InputDecoration(
          hintText: 'Find Course',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Container(
            margin: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEEEEE),
            ),
            child: const Icon(Icons.tune, color: Colors.grey, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // --- ปรับปรุง Category Filter ให้เหมือนในรูป (Card สี่เหลี่ยมมีไอคอน) ---
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 110, // เพิ่มความสูงให้ใส่ไอคอนได้
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          // กำหนดสีและไอคอนตามหมวดหมู่ (Custom Style)
          Color cardColor;
          Color contentColor;
          IconData iconData;

          if (category == 'Maths') {
            cardColor = const Color(0xFFE3F2FD); // ฟ้าอ่อน
            contentColor = const Color(0xFF1E88E5); // ฟ้าเข้ม
            iconData = Icons.calculate_outlined;
          } else if (category == 'Robotic') {
            cardColor = const Color(0xFFF3E5F5); // ม่วงอ่อน
            contentColor = const Color(0xFF8E24AA); // ม่วงเข้ม
            iconData = Icons.smart_toy_outlined;
          } else {
            cardColor = Colors.white;
            contentColor = Colors.grey.shade700;
            iconData = Icons.category_outlined;
          }

          // ถ้าถูกเลือก ให้สีเข้มขึ้นหรือมีขอบ
          if (isSelected) {
            cardColor = contentColor.withOpacity(0.1);
          }

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
              _fetchCoursesWithFilter();
            },
            child: Container(
              width: 100, // ความกว้างของ Card
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: contentColor, width: 2) : null,
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ไอคอนในวงกลม
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: contentColor, size: 28),
                  ),
                  const SizedBox(height: 8),
                  // ชื่อหมวดหมู่
                  Text(
                    category,
                    style: TextStyle(
                      color: contentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- ปรับปรุง Sort Chips ---
  Widget _buildSortFilter() {
    final sortOptions = ['All', 'Popular', 'New'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: sortOptions.map((option) {
          final isSelected = option == _selectedSort;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedSort = option);
                _fetchCoursesWithFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- ส่วนแสดงรายการ (Loading / Error / List) ---
  Widget _buildCourseListResult() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
      );
    }
    if (_allCourses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey),
              Text('No courses found', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16), // เว้นขอบซ้ายขวา
      itemCount: _allCourses.length,
      itemBuilder: (context, index) {
        return CourseCard(course: _allCourses[index]);
      },
    );
  }
}

// ******************************************************
// 3. COURSE CARD WIDGET (ปรับปรุงให้สวยงาม)
// ******************************************************
class CourseCard extends StatelessWidget {
  final CourseModel course;
  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // ระยะห่างระหว่างการ์ด
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 1. รูปภาพคอร์ส (มุมโค้ง)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey.shade200,
                child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                    ? Image.network(
                  course.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
                )
                    : const Icon(Icons.image, color: Colors.grey), // Placeholder
              ),
            ),
            const SizedBox(width: 16),

            // 2. รายละเอียดคอร์ส
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อคอร์ส
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // ผู้สอน
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.instructor,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ราคาและเวลา
                  Row(
                    children: [
                      Text(
                        '${course.price} Bath',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5), // สีฟ้าเน้นราคา
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0), // พื้นหลังสีส้มอ่อน
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${course.durationHours} hours',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100), // ตัวหนังสือสีส้มเข้ม
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}