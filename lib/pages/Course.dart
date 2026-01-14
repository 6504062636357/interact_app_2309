import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import '../services/api_service.dart';
import '../model/course.model.dart';
import 'CourseDetail.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  // --- Data Variables ---
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // --- Filter State ---
  String _selectedCategory = 'All';
  String _selectedSort = 'All';
  String _searchText = '';
  RangeValues _priceRange = const RangeValues(0, 25000);
  String? _selectedDuration;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCoursesWithFilter();

    _searchController.addListener(() {
      if (_searchText != _searchController.text) {
        setState(() {
          _searchText = _searchController.text;
        });
        _fetchCoursesWithFilter();
      }
    });
  }

  Future<void> _fetchCoursesWithFilter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      String? categoryParam = (_selectedCategory == 'All') ? null : _selectedCategory;
      String? sortParam = (_selectedSort == 'All') ? null : _selectedSort.toLowerCase();
      String? searchParam = _searchText.isEmpty ? null : _searchText;

      final courseData = await ApiService.getCourses(
        category: categoryParam,
        sort: sortParam,
        search: searchParam,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      );

      setState(() {
        _allCourses = courseData.map((json) => CourseModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

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
              const Text("Search Filter",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        bool isSel = _selectedCategory == cat;
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
                        Text("\$${_priceRange.end.toInt()}", style: const TextStyle(color: Colors.grey))
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _priceRange = const RangeValues(0, 25000);
                            _selectedDuration = null;
                          });
                          Navigator.pop(context);
                          _fetchCoursesWithFilter();
                        },
                        child: const Text("Clear", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A68FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchCoursesWithFilter();
                        },
                        child: const Text("Apply Filter",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        title: const Text('Course', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: GestureDetector(
        onTap: () => OnscreenKeyboard.of(context).close(),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFFC107),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchCoursesWithFilter,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    _buildFixedCategories(),
                    const SizedBox(height: 25),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Choice your course", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _buildSortTabs(),
                    _buildCourseList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: OnscreenKeyboardTextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Find Course',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterBottomSheet,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFixedCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _categoryCard("Maths", const Color(0xFFE3F2FD), Colors.blue, Icons.calculate),
          const SizedBox(width: 15),
          _categoryCard("Robotic", const Color(0xFFF3E5F5), Colors.purple, Icons.smart_toy),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, Color bg, Color textCol, IconData icon) {
    bool isSelected = _selectedCategory == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          OnscreenKeyboard.of(context).close();
          setState(() {
            _selectedCategory = isSelected ? 'All' : title;
          });
          _fetchCoursesWithFilter();
        },
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? Border.all(color: textCol, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textCol, size: 30),
              Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: ['All', 'Popular', 'New'].map((tab) {
          bool isSel = _selectedSort == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () {
                OnscreenKeyboard.of(context).close();
                setState(() => _selectedSort = tab);
                _fetchCoursesWithFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF4A68FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tab, style: TextStyle(color: isSel ? Colors.white : Colors.grey)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()));
    if (_allCourses.isEmpty) return const Center(child: Text("No courses found"));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _allCourses.length,
      itemBuilder: (context, index) {
        final course = _allCourses[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailPage(course: course),
              ),
            );
          },
          child: CourseCard(course: course),
        );
      },
    );
  }
} // ปิด Class _CoursePageState

// --- คลาส CourseCard แยกออกมาอยู่ด้านนอกให้ถูกต้อง ---
class CourseCard extends StatelessWidget {
  final CourseModel course;
  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              image: course.imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(course.imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: course.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(course.instructor, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${course.price} Bath",
                          style: const TextStyle(color: Color(0xFF4A68FF), fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: Text("${course.durationHours} hours",
                            style: const TextStyle(
                                color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ))
        ],
      ),
    );
  }
}