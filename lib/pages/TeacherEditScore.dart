import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class EditStudentScore extends StatefulWidget {
  final String studentName;
  final int index;
  final Map scores;
  final String gradeId;
  final List columns;

  const EditStudentScore({
    super.key,
    required this.studentName,
    required this.index,
    required this.scores,
    required this.gradeId,
    required this.columns,
  });

  @override
  State<EditStudentScore> createState() => _EditStudentScoreState();
}

class _EditStudentScoreState extends State<EditStudentScore> {
  Map<String, TextEditingController> controllers = {};
  final TextEditingController _commentController = TextEditingController();
  Map<String, int> maxMap = {};

  @override
  void initState() {
    super.initState();

    for (var col in widget.columns) {
      final key = col['key'];

      maxMap[key] = col['max'];

      controllers[key] = TextEditingController(
        text: (widget.scores[key] ?? 0).toString(),
      );
    }

    _commentController.text = widget.scores["comment"] ?? "";
  }

  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  int getTotalScore() {
    int total = 0;
    controllers.forEach((key, c) {
      total += int.tryParse(c.text) ?? 0;
    });
    return total;
  }

  Future<void> saveScore() async {
    Map<String, int> newScores = {};

    controllers.forEach((key, controller) {
      newScores[key] = int.tryParse(controller.text) ?? 0;
    });

    final res = await http.patch(
      Uri.parse("${AppConfig.baseUrl}/api/grades/${widget.gradeId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "scores": newScores,
        "comment": _commentController.text,
      }),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Save failed")),
      );
    }
  }

  //  input ที่กันเกิน max แบบจริงจัง
  Widget _input(String key, TextEditingController c) {
    final max = maxMap[key] ?? 100;

    return SizedBox(
      width: 150,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onChanged: (val) {
          int value = int.tryParse(val) ?? 0;

          if (value > max) {
            // ❌ กันไม่ให้เกิน
            c.text = max.toString();
            c.selection = TextSelection.fromPosition(
              TextPosition(offset: c.text.length),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("❌ $key ห้ามเกิน $max"),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (value < 0) {
            c.text = "0";
          }

          setState(() {});
        },
        decoration: InputDecoration(
          labelText: "$key (/$max)",
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD64F),
        elevation: 0,
        centerTitle: true,
        title: const Text("Edit Score",
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🔹 HEADER (เอากลับมาเหมือนของเดิม)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.studentName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text("Student #${widget.index}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 SCORE CARD (dynamic แต่หน้าตาเดิม)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Scores",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.columns.map<Widget>((col) {
                      final key = col['key'];
                      return _input(key, controllers[key]!);
                    }).toList(),
                  ),

                  const SizedBox(height: 15),

                  Text("Total: ${getTotalScore()}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 COMMENT CARD (เหมือนเดิม)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Comment",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write comment...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 SAVE BUTTON (เหมือนเดิม)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FD06C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Save Changes",
                    style:
                    TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}