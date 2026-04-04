import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:interact_app_2309/config.dart';
import 'ProgressStudentDetail.dart';

// ─────────────────────────────────────────────
//  Data model สำหรับแต่ละ bar
// ─────────────────────────────────────────────
class _BarItem {
  final String label;
  final double myScore;
  final double classAvg;
  final double maxScore;

  const _BarItem({
    required this.label,
    required this.myScore,
    required this.classAvg,
    required this.maxScore,
  });
}

// ─────────────────────────────────────────────
//  ProgressStudent Widget
// ─────────────────────────────────────────────
class ProgressStudent extends StatefulWidget {
  const ProgressStudent({super.key});

  @override
  State<ProgressStudent> createState() => _ProgressStudentState();
}

class _ProgressStudentState extends State<ProgressStudent> {
  List courses = [];
  bool loading = true;
  String selectedPeriod = "Weekly";

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/grades/analysis/$uid"),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          courses = data;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ── helpers ──────────────────────────────────

  double _getAvgPercent() {
    if (courses.isEmpty) return 0;
    double total = 0;
    for (var c in courses) {
      total += ((c['summary']?['percentage'] ?? 0) as num).toDouble();
    }
    return total / courses.length;
  }

  int _getTotalTests() {
    int total = 0;
    for (var c in courses) {
      total += ((c['summary']?['columns'] ?? []) as List).length;
    }
    return total;
  }

  /// รวม bar items จากทุกวิชา (max 7 แท่ง)
  List<_BarItem> _buildBars() {
    final List<_BarItem> bars = [];
    for (var c in courses) {
      final cols = (c['summary']?['columns'] ?? []) as List;
      final myScores = (c['my_scores'] ?? {}) as Map;
      final classAvg = (c['class_avg'] ?? {}) as Map;
      for (var col in cols) {
        final key = col['key'];
        final maxRaw = col['max'];
        final max = maxRaw != null
            ? (maxRaw as num).toDouble()
            : 100.0;
        final my = ((myScores[key] ?? 0) as num).toDouble();
        final avg = ((classAvg[key] ?? 0) as num).toDouble();
        bars.add(_BarItem(
          label: col['label']?.toString() ?? key,
          myScore: my,
          classAvg: avg,
          maxScore: max,
        ));
        if (bars.length >= 7) return bars;
      }
    }
    return bars;
  }

  /// Line chart: ใช้ percentage ของแต่ละวิชาเทียบกัน
  List<double> _myTrend() => courses
      .map<double>(
          (c) => ((c['summary']?['percentage'] ?? 0) as num).toDouble())
      .toList();

  List<double> _avgTrend() {
    // ถ้า API ส่ง class_avg_percentage มาให้ใช้เลย
    // ถ้าไม่มีให้ประมาณจาก class_avg_total / max_total
    return courses.map<double>((c) {
      final s = c['summary'] ?? {};
      if (s['class_avg_percentage'] != null) {
        return (s['class_avg_percentage'] as num).toDouble();
      }
      final maxTotal = (s['max_total'] ?? 0) as num;
      final classTotal = (s['class_avg_total'] ?? 0) as num;
      if (maxTotal <= 0) return 0;
      return (classTotal / maxTotal * 100).toDouble();
    }).toList();
  }

  List<String> _trendLabels() => courses
      .asMap()
      .entries
      .map((e) => "C${e.key + 1}")
      .toList();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F4C5C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? "User";
    final avgPercent = _getAvgPercent();
    final totalTests = _getTotalTests();
    final bars = _buildBars();
    final myTrend = _myTrend();
    final avgTrend = _avgTrend();
    final trendLabels = _trendLabels();

    // improvement = selisih first & last
    String improvementText = "";
    if (myTrend.length >= 2) {
      final diff = (myTrend.last - myTrend.first).round();
      improvementText = "${diff >= 0 ? '+' : ''}$diff% improvement";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F4C5C),
      body: Column(
        children: [
          const SizedBox(height: 50),

          // ── HEADER ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hi, $userName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── WHITE BODY ──────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: courses.isEmpty
                  ? const Center(
                  child: Text("ยังไม่มีข้อมูลการเรียน",
                      style: TextStyle(color: Colors.grey)))
                  : ListView(
                padding:
                const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  // ── Title + toggle ─────────────────────
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Learning Progress",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Track your study performance",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      _PeriodToggle(
                        selected: selectedPeriod,
                        onChanged: (v) =>
                            setState(() => selectedPeriod = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── BAR CHART ─────────────────────────
                  if (bars.isNotEmpty)
                    _DualBarChart(bars: bars),

                  const SizedBox(height: 20),

                  // ── SUMMARY CARDS ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: "Total Enrolled",
                          value: "${courses.length}",
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFB300),
                              Color(0xFFFFA000)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: "Quiz Score",
                          value:
                          "${avgPercent.toStringAsFixed(0)}%",
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B35),
                              Color(0xFFFF4500)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: "Tests Taken",
                          value: "$totalTests",
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF26C6DA),
                              Color(0xFF00ACC1)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── SUBJECTS ──────────────────────────
                  Row(
                    children: const [
                      Text("Subjects",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      SizedBox(width: 6),
                      Text("(summary feedback)",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ...courses.map((c) => _SubjectTile(
                    course: c,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProgressStudentDetail(data: c)),
                    ),
                  )),

                  const SizedBox(height: 28),

                  // ── LINE CHART (Overall Performance) ──
                  if (myTrend.length >= 2) ...[
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Overall Performance",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        if (improvementText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_upward,
                                    size: 12,
                                    color: Colors.green),
                                const SizedBox(width: 2),
                                Text(
                                  improvementText,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AreaLineChart(
                      myPoints: myTrend,
                      avgPoints: avgTrend,
                      xLabels: trendLabels,
                    ),
                    const SizedBox(height: 10),
                    // Legend
                    Row(
                      children: const [
                        _Dot(
                            color: Color(0xFFFF6B35),
                            label: "Quiz Score"),
                        SizedBox(width: 16),
                        _Dot(
                            color: Color(0xFF90CAF9),
                            label: "Class Average"),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  Period Toggle
// ════════════════════════════════════════════════
class _PeriodToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: ["Weekly", "Monthly"].map((label) {
          final active = selected == label;
          return GestureDetector(
            onTap: () => onChanged(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF0F4C5C)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  Dual Bar Chart  (my score = orange | avg = blue)
// ════════════════════════════════════════════════
class _DualBarChart extends StatelessWidget {
  final List<_BarItem> bars;

  const _DualBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    // หา chartMax จาก maxScore ของทุก bar
    final double chartMax = bars.fold<double>(
      0,
          (p, b) => b.maxScore > p ? b.maxScore : p,
    );
    final double safeMax = chartMax > 0 ? chartMax : 100;
    const double chartH = 150.0;
    const double barW = 14.0;

    // หา bar ที่ myScore สูงสุด (ใส่ star + label)
    final double topMy =
    bars.map((b) => b.myScore).reduce((a, c) => a > c ? a : c);

    return SizedBox(
      height: chartH + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 4; i >= 0; i--)
                Text(
                  (safeMax * i / 4).toInt().toString(),
                  style: const TextStyle(
                      fontSize: 9, color: Color(0xFFB0BEC5)),
                ),
              const SizedBox(height: 24), // space for x labels
            ],
          ),
          const SizedBox(width: 4),

          // Bars + grid
          Expanded(
            child: CustomPaint(
              painter: _GridLinePainter(chartH: chartH),
              child: Column(
                children: [
                  // bars row
                  SizedBox(
                    height: chartH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: bars.map((b) {
                        final myH =
                            (b.myScore / safeMax) * chartH;
                        final avgH =
                            (b.classAvg / safeMax) * chartH;
                        final isTop = b.myScore == topMy;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // badge label ถ้าเป็น top
                            if (isTop)
                              Column(
                                children: [
                                  Text(
                                    "${b.myScore.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const Icon(Icons.star,
                                      size: 11,
                                      color: Color(0xFFFFC107)),
                                ],
                              )
                            else
                              const SizedBox(height: 20),

                            // pair of bars
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                // avg (blue)
                                _RoundBar(
                                  height: avgH,
                                  width: barW,
                                  color: const Color(0xFFB3D4F5),
                                ),
                                const SizedBox(width: 3),
                                // my score (orange)
                                _RoundBar(
                                  height: myH,
                                  width: barW,
                                  color: const Color(0xFFFF6B35),
                                  glowing: isTop,
                                ),
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  // x labels
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: bars
                          .map((b) => SizedBox(
                        width: barW * 2 + 3,
                        child: Text(
                          b.label,
                          style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF90A4AE)),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBar extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final bool glowing;

  const _RoundBar({
    required this.height,
    required this.width,
    required this.color,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.clamp(4.0, double.infinity),
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        boxShadow: glowing
            ? [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ]
            : null,
      ),
    );
  }
}

class _GridLinePainter extends CustomPainter {
  final double chartH;

  const _GridLinePainter({required this.chartH});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ════════════════════════════════════════════════
//  Summary Card
// ════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Gradient gradient;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  Subject Tile
// ════════════════════════════════════════════════
class _SubjectTile extends StatelessWidget {
  final dynamic course;
  final VoidCallback onTap;

  const _SubjectTile({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                course['course_title']?.toString() ?? "Course",
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F4C5C)),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF0F4C5C)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  Area Line Chart  (เส้นโค้ง + fill area)
// ════════════════════════════════════════════════
class _AreaLineChart extends StatelessWidget {
  final List<double> myPoints;
  final List<double> avgPoints;
  final List<String> xLabels;

  const _AreaLineChart({
    required this.myPoints,
    required this.avgPoints,
    required this.xLabels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _AreaLinePainter(
          myPoints: myPoints,
          avgPoints: avgPoints,
          xLabels: xLabels,
        ),
      ),
    );
  }
}

class _AreaLinePainter extends CustomPainter {
  final List<double> myPoints;
  final List<double> avgPoints;
  final List<String> xLabels;

  const _AreaLinePainter({
    required this.myPoints,
    required this.avgPoints,
    required this.xLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (myPoints.isEmpty) return;

    const double padLeft = 36;
    const double padRight = 12;
    const double padTop = 20;
    const double padBottom = 28;

    final double chartW = size.width - padLeft - padRight;
    final double chartH = size.height - padTop - padBottom;

    // ── collect all values to find min/max ──
    final allValues = [...myPoints, ...avgPoints];
    final double minV = (allValues.reduce(min) * 0.85).clamp(0, 100);
    final double maxV = (allValues.reduce(max) * 1.1).clamp(minV + 1, 110);
    final double range = maxV - minV;

    double xOf(int i) =>
        padLeft + (i / (myPoints.length - 1)) * chartW;
    double yOf(double v) =>
        padTop + chartH * (1 - (v - minV) / range);

    // ── grid lines ──────────────────────────
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartH * i / 4;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y),
          gridPaint);
      // y label
      final val = maxV - range * i / 4;
      final tp = TextPainter(
        text: TextSpan(
          text: val.toInt().toString(),
          style: const TextStyle(fontSize: 9, color: Color(0xFFB0BEC5)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    // ── helper: build smooth path ─────────────
    Path buildPath(List<double> pts) {
      final path = Path();
      for (int i = 0; i < pts.length; i++) {
        final x = xOf(i);
        final y = yOf(pts[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = xOf(i - 1);
          final prevY = yOf(pts[i - 1]);
          final cpX = (prevX + x) / 2;
          path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
      }
      return path;
    }

    // ── avg fill area (blue) ─────────────────
    final avgPath = buildPath(avgPoints);
    final avgFill = Path.from(avgPath)
      ..lineTo(xOf(avgPoints.length - 1), padTop + chartH)
      ..lineTo(padLeft, padTop + chartH)
      ..close();
    canvas.drawPath(
      avgFill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF90CAF9).withOpacity(0.45),
            const Color(0xFF90CAF9).withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, padTop, size.width, chartH)),
    );
    // avg line
    canvas.drawPath(
      avgPath,
      Paint()
        ..color = const Color(0xFF90CAF9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── my score fill area (orange) ──────────
    final myPath = buildPath(myPoints);
    final myFill = Path.from(myPath)
      ..lineTo(xOf(myPoints.length - 1), padTop + chartH)
      ..lineTo(padLeft, padTop + chartH)
      ..close();
    canvas.drawPath(
      myFill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.25),
            const Color(0xFFFF6B35).withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, padTop, size.width, chartH)),
    );
    // my score line
    canvas.drawPath(
      myPath,
      Paint()
        ..color = const Color(0xFFFF6B35)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── dots on my score line ─────────────────
    final dotPaint = Paint()..color = const Color(0xFFFF6B35);
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < myPoints.length; i++) {
      final cx = xOf(i);
      final cy = yOf(myPoints[i]);
      canvas.drawCircle(Offset(cx, cy), 5, dotPaint);
      canvas.drawCircle(Offset(cx, cy), 5, dotBorder);
    }

    // ── x labels ─────────────────────────────
    for (int i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: const TextStyle(fontSize: 9, color: Color(0xFF90A4AE)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(xOf(i) - tp.width / 2, size.height - padBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _AreaLinePainter old) =>
      old.myPoints != myPoints ||
          old.avgPoints != avgPoints ||
          old.xLabels != xLabels;
}

// ════════════════════════════════════════════════
//  Legend dot
// ════════════════════════════════════════════════
class _Dot extends StatelessWidget {
  final Color color;
  final String label;

  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}