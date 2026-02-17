import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import '../model/course.model.dart';
import '../services/api_service.dart';
import 'CourseDetail.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String _selectedCategory = 'All';
  String _selectedSort = 'All';
  String _searchText = '';
  RangeValues _priceRange = const RangeValues(0, 25000);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCoursesWithFilter();
  }

  Future<void> _fetchCoursesWithFilter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final courseData = await ApiService.getCourses(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        sort: _selectedSort == 'All' ? null : _selectedSort.toLowerCase(),
        search: _searchText.isEmpty ? null : _searchText,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      );

      setState(() {
        _allCourses =
            courseData.map((json) => CourseModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allCourses.length,
                  itemBuilder: (context, index) {
                    final course = _allCourses[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseDetailPage(course: course),
                          ),
                        );
                      },
                      child: CourseCard(course: course),
                    );
                  },
                ),
    );
  }
}

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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
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
                  ? DecorationImage(
                      image: NetworkImage(course.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: course.imageUrl.isEmpty
                ? const Icon(Icons.image)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  course.instructor,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${course.price} Bath",
                      style: const TextStyle(
                        color: Color(0xFF4A68FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("${course.durationHours} hours"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
