import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interact_app_2309/config.dart';
import 'TeacherEditScore.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class TeacherGradeBook extends StatefulWidget {
  final String teacherAuthUid; // ✅ รับ UID ครูจาก Dashboard

  const TeacherGradeBook({
    super.key,
    required this.teacherAuthUid,
  });

  @override
  State<TeacherGradeBook> createState() => _TeacherGradeBookState();
}

class _TeacherGradeBookState extends State<TeacherGradeBook> {
  List grades = [];
  bool isLoading = true;
  List columns = [];//
  String? courseId;//
  late String teacherUid;

  @override
  void initState() {
    super.initState();

    if (widget.teacherAuthUid == null || widget.teacherAuthUid.isEmpty) {
      print("❌ teacherAuthUid is null");
      return;
    }

    teacherUid = widget.teacherAuthUid;
    fetchGrades(teacherUid);
  }
  // 🔄 ดึงข้อมูลเกรด
  Future<void> fetchGrades(String teacherUid) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/grades/teacher-grades/$teacherUid"),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          //grades = json.decode(response.body);
          final data = json.decode(response.body);

          grades = data["grades"];
          columns = data["columns"];
          courseId = data["course_id"];
          isLoading = false;
        });
      } else {
        print("Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Connection Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double totalTableWidth = 1200.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: Column(
          children: [
            _buildYellowHeader(),
            _buildColumnManager(),
            Expanded(
              child: SingleChildScrollView(
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 10,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: totalTableWidth,
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Column(
                        children: [
                          _buildTableHeader(),
                          const Divider(height: 1),
                          grades.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("No students found."),
                          )
                              : ListView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: grades.length,
                            itemBuilder: (context, index) =>
                                _buildStudentRow(
                                    context, grades[index], index + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 50, child: Text("Edit", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 160, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold))),

          // dynamic columns
          ...columns.map<Widget>((col) {
            return _cell(col['label']);
          }).toList(),

          _cell("Comment", width: 300),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, dynamic grade, int index) {
    final scores = grade["scores"] ?? {};
    final name = grade["student_name"] ?? "No Name";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text("$index", style: const TextStyle(color: Colors.black45))),

          SizedBox(
            width: 50,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditStudentScore(
                      studentName: name,
                      index: index,
                      scores: scores,
                      gradeId: grade["_id"],
                      columns: columns,
                    ),
                  ),
                );
                fetchGrades(teacherUid);
              },
              child: Icon(Icons.edit_note, color: Colors.orange.shade400, size: 28),
            ),
          ),

          SizedBox(
            width: 160,
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),

          // 🔥 dynamic columns
          ...columns.map<Widget>((col) {
            final key = col['key'];
            final max = col['max'];
            final value = scores[key] ?? 0;

            return _badge("$value/$max", const Color(0xFF4FD18B));
          }).toList(),

          Container(
            width: 300,
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade["comment"] ?? "-",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String txt, {double width = 85}) => SizedBox(
      width: width,
      child: Center(
          child: Text(txt,
              style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _badge(String txt, Color col) => Container(
    width: 75,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration:
    BoxDecoration(color: col, borderRadius: BorderRadius.circular(20)),
    child: Center(
      child: Text(txt,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildYellowHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, left: 24, bottom: 20),
    color: const Color(0xFFFFD64F),
    child: const Text(
      "Student Assessment",
      style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white),
    ),
  );
  Future<void> addColumn(String label, int max) async {
    await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/grades/add-column"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "course_id": courseId,
        "label": label,
        "max": max,
      }),
    );

    fetchGrades(teacherUid);
  }

  Future<void> removeColumn(String key) async {
    final request = http.Request(
      'DELETE',
      Uri.parse("${AppConfig.baseUrl}/api/grades/remove-column"),
    );

    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      "course_id": courseId,
      "key": key
    });

    await request.send();

    fetchGrades(teacherUid);
  }

  Future<void> updateColumn(String key, String label, int max) async {
    await http.patch(
      Uri.parse("${AppConfig.baseUrl}/api/grades/update-column"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "course_id": courseId,
        "key": key,
        "label": label,
        "max": max,
      }),
    );

    fetchGrades(teacherUid);
  }

  void showAddColumnDialog() {
    final label = TextEditingController();
    final max = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Column"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: "Label")),
            TextField(controller: max, decoration: const InputDecoration(labelText: "Max"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              addColumn(label.text, int.tryParse(max.text) ?? 10);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void showEditColumnDialog(dynamic col) {
    final label = TextEditingController(text: col['label']);
    final max = TextEditingController(text: col['max'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Column"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: label),
            TextField(controller: max, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              updateColumn(col['key'], label.text, int.tryParse(max.text) ?? 10);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }


  Widget _buildColumnManager() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          const Text("Columns:",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(width: 10),

          // 🔁 list columns
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: columns.map<Widget>((col) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text("${col['label']} (/${col['max']})"),

                        // ✏️ edit
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () {
                            showEditColumnDialog(col);
                          },
                        ),

                        // ❌ delete
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.red),
                          onPressed: () {
                            removeColumn(col['key']);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ➕ add
          IconButton(
            icon: const Icon(Icons.add_circle,
                color: Colors.orange, size: 30),
            onPressed: showAddColumnDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() => Padding(
    padding: const EdgeInsets.all(20),
    child: ElevatedButton(
      onPressed: () => fetchGrades(teacherUid),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3FD06C),
        minimumSize: const Size(double.infinity, 50),
        shape: const StadiumBorder(),
      ),
      child: const Text("Refresh Data",
          style: TextStyle(color: Colors.white, fontSize: 18)),
    ),
  );
}