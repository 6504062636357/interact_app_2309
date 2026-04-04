import 'package:flutter/material.dart';
import 'dart:math';

class ProgressStudentDetail extends StatelessWidget {
  final Map data;

  const ProgressStudentDetail({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] ?? {};
    final List columns = List.from(summary['columns'] ?? []);
    final Map myScores = Map.from(data['my_scores'] ?? {});
    final Map classAvg = Map.from(data['class_avg'] ?? {});

    final int myTotal = (summary['my_total'] ?? 0) as int;
    final int classTotal = ((summary['class_avg_total'] ?? 0) as num).round();
    final int percent = (summary['percentage'] ?? 0) as int;
    final String comment = (data['comment'] ?? '').toString();
    final int diff = myTotal - classTotal;

    // ── ranking label ──
    String rankLabel;
    String rankSub;
    Color rankColor;
    IconData rankIcon;
    if (percent >= 80) {
      rankLabel = 'Top Student';
      rankSub = 'Outstanding! You\'re among the best in class.';
      rankColor = const Color(0xFFFFB300);
      rankIcon = Icons.emoji_events;
    } else if (percent >= 60) {
      rankLabel = 'Above Average';
      rankSub = 'Good work! Keep pushing to reach the top.';
      rankColor = Colors.green;
      rankIcon = Icons.thumb_up_alt;
    } else {
      rankLabel = 'Keep Improving';
      rankSub = 'Consistent effort will pay off. You got this!';
      rankColor = Colors.orangeAccent;
      rankIcon = Icons.trending_up;
    }

    // ── build bar items from columns ──
    final List<_BarItem> bars = columns.map<_BarItem>((col) {
      final key = col['key'];
      final max = ((col['max'] ?? 100) as num).toDouble();
      final my = ((myScores[key] ?? 0) as num).toDouble();
      final avg = ((classAvg[key] ?? 0) as num).toDouble();
      return _BarItem(
        label: col['label']?.toString() ?? key,
        myScore: my,
        classAvg: avg,
        maxScore: max,
      );
    }).toList();

    // ── build % trend (each quiz score / max * 100) ──
    final List<double> myTrend = columns.map<double>((col) {
      final key = col['key'];
      final max = ((col['max'] ?? 100) as num).toDouble();
      final my = ((myScores[key] ?? 0) as num).toDouble();
      return max > 0 ? (my / max * 100) : 0.0;
    }).toList();

    final List<double> avgTrend = columns.map<double>((col) {
      final key = col['key'];
      final max = ((col['max'] ?? 100) as num).toDouble();
      final avg = ((classAvg[key] ?? 0) as num).toDouble();
      return max > 0 ? (avg / max * 100) : 0.0;
    }).toList();

    final List<String> xLabels =
    columns.map<String>((col) => col['label']?.toString() ?? '').toList();

    // improvement badge
    String improvementText = '';
    if (myTrend.length >= 2) {
      final d = (myTrend.last - myTrend.first).round();
      improvementText = '${d >= 0 ? '+' : ''}$d% improvement';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F4C5C),
      body: Column(
        children: [
          const SizedBox(height: 50),

          // ── HEADER ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    data['course_title']?.toString() ?? 'Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 10),
              ],
            ),
          ),

          // ── WHITE BODY ──────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [

                  // ── SECTION: Quiz Scores (Bar Chart) ─
                  _SectionTitle(
                    title: 'Quiz Scores',
                    subtitle: 'My score vs Class average',
                    trailing: bars.isNotEmpty
                        ? _LegendRow()
                        : null,
                  ),
                  const SizedBox(height: 14),

                  if (bars.isNotEmpty)
                    _DualBarChart(bars: bars)
                  else
                    const _EmptyChart(),

                  const SizedBox(height: 24),

                  // ── STAT CARDS ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'You',
                          value: '$myTotal',
                          color: const Color(0xFFFF6B35),
                          icon: Icons.emoji_events,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Class Avg',
                          value: '$classTotal',
                          color: const Color(0xFF42A5F5),
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Diff',
                          value: '${diff >= 0 ? '+' : ''}$diff',
                          color: diff >= 0 ? Colors.green : Colors.redAccent,
                          icon: diff >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── SECTION: Overall Performance (Line) ─
                  if (myTrend.length >= 2) ...[
                    _SectionTitle(
                      title: 'Overall Performance',
                      subtitle: 'Score % per quiz',
                      trailing: improvementText.isNotEmpty
                          ? _ImprovementBadge(text: improvementText,
                          positive: myTrend.last >= myTrend.first)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _AreaLineChart(
                      myPoints: myTrend,
                      avgPoints: avgTrend,
                      xLabels: xLabels,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        _Dot(color: Color(0xFFFF6B35), label: 'Quiz Score'),
                        SizedBox(width: 16),
                        _Dot(color: Color(0xFF90CAF9), label: 'Class Average'),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── RANKING ───────────────────────────
                  _RankingCard(
                    label: rankLabel,
                    sub: rankSub,
                    color: rankColor,
                    icon: rankIcon,
                    percent: percent,
                  ),

                  const SizedBox(height: 16),

                  // ── COMMENT ───────────────────────────
                  _CommentCard(comment: comment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Data model
// ══════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════
//  Section Title
// ══════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  Legend Row
// ══════════════════════════════════════════════════
class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _Dot(color: Color(0xFFFF6B35), label: 'Mine'),
        SizedBox(height: 4),
        _Dot(color: Color(0xFF90CAF9), label: 'Avg'),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  Improvement Badge
// ══════════════════════════════════════════════════
class _ImprovementBadge extends StatelessWidget {
  final String text;
  final bool positive;
  const _ImprovementBadge({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Dual Bar Chart  (custom painter — no fl_chart)
// ══════════════════════════════════════════════════
class _DualBarChart extends StatelessWidget {
  final List<_BarItem> bars;
  const _DualBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    // chartMax = highest maxScore across all bars
    final double chartMax = bars.fold<double>(
      0,
          (p, b) => b.maxScore > p ? b.maxScore : p,
    );
    final double safeMax = chartMax > 0 ? chartMax : 100;
    const double chartH = 160.0;
    const double barW = 13.0;

    final double topMy =
    bars.map((b) => b.myScore).reduce((a, c) => a > c ? a : c);

    return SizedBox(
      height: chartH + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis labels
          SizedBox(
            width: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 4; i >= 0; i--)
                  Text(
                    (safeMax * i / 4).toInt().toString(),
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFFB0BEC5)),
                  ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: CustomPaint(
              painter: _GridPainter(chartH: chartH),
              child: Column(
                children: [
                  // Bars
                  SizedBox(
                    height: chartH,
                    child: LayoutBuilder(builder: (ctx, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: bars.map((b) {
                          final myH =
                          (b.myScore / safeMax * chartH).clamp(3.0, chartH);
                          final avgH =
                          (b.classAvg / safeMax * chartH).clamp(3.0, chartH);
                          final isTop = b.myScore == topMy && topMy > 0;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Top label + star
                              if (isTop)
                                Column(children: [
                                  Text(
                                    b.myScore.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const Icon(Icons.star,
                                      size: 11,
                                      color: Color(0xFFFFC107)),
                                ])
                              else
                                const SizedBox(height: 22),

                              // Bar pair
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _Bar(
                                    height: avgH,
                                    width: barW,
                                    color: const Color(0xFF90CAF9),
                                  ),
                                  const SizedBox(width: 3),
                                  _Bar(
                                    height: myH,
                                    width: barW,
                                    color: const Color(0xFFFF6B35),
                                    glow: isTop,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }),
                  ),

                  // X labels
                  SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: bars.map((b) {
                        return SizedBox(
                          width: barW * 2 + 3,
                          child: Text(
                            b.label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF90A4AE)),
                          ),
                        );
                      }).toList(),
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

class _Bar extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final bool glow;

  const _Bar({
    required this.height,
    required this.width,
    required this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        boxShadow: glow
            ? [
          BoxShadow(
            color: color.withOpacity(0.55),
            blurRadius: 10,
            offset: const Offset(0, -3),
          )
        ]
            : null,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double chartH;
  const _GridPainter({required this.chartH});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ══════════════════════════════════════════════════
//  Empty Chart placeholder
// ══════════════════════════════════════════════════
class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text('ยังไม่มีข้อมูลคะแนน',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Stat Card
// ══════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
              const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Area Line Chart  (smooth bezier + fill)
// ══════════════════════════════════════════════════
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
      height: 180,
      child: CustomPaint(
        painter: _AreaPainter(
          myPoints: myPoints,
          avgPoints: avgPoints,
          xLabels: xLabels,
        ),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> myPoints;
  final List<double> avgPoints;
  final List<String> xLabels;

  const _AreaPainter({
    required this.myPoints,
    required this.avgPoints,
    required this.xLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (myPoints.isEmpty) return;

    const double padL = 32;
    const double padR = 12;
    const double padT = 20;
    const double padB = 30;

    final double w = size.width - padL - padR;
    final double h = size.height - padT - padB;

    final all = [...myPoints, ...avgPoints];
    final double minV = (all.reduce(min) * 0.85).clamp(0.0, 99.0);
    final double maxV = (all.reduce(max) * 1.08).clamp(minV + 1, 110.0);
    final double range = maxV - minV;

    final int n = myPoints.length;
    double xOf(int i) => padL + (i / (n - 1)) * w;
    double yOf(double v) => padT + h * (1 - (v - minV) / range);

    // ── grid ──
    final gridP = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padT + h * i / 4;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridP);
      final val = maxV - range * i / 4;
      _drawText(canvas, val.toInt().toString(),
          Offset(0, y - 7), const TextStyle(fontSize: 9, color: Color(0xFFB0BEC5)));
    }

    // ── smooth path builder ──
    Path smooth(List<double> pts) {
      final path = Path();
      for (int i = 0; i < pts.length; i++) {
        final x = xOf(i);
        final y = yOf(pts[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final px = xOf(i - 1);
          final py = yOf(pts[i - 1]);
          final cx = (px + x) / 2;
          path.cubicTo(cx, py, cx, y, x, y);
        }
      }
      return path;
    }

    // ── avg area (blue) ──
    final avgPath = smooth(avgPoints);
    final avgFill = Path.from(avgPath)
      ..lineTo(xOf(n - 1), padT + h)
      ..lineTo(padL, padT + h)
      ..close();
    canvas.drawPath(
      avgFill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF90CAF9).withOpacity(0.45),
            const Color(0xFF90CAF9).withOpacity(0.04),
          ],
        ).createShader(Rect.fromLTWH(0, padT, size.width, h)),
    );
    canvas.drawPath(
      avgPath,
      Paint()
        ..color = const Color(0xFF90CAF9)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── my area (orange) ──
    final myPath = smooth(myPoints);
    final myFill = Path.from(myPath)
      ..lineTo(xOf(n - 1), padT + h)
      ..lineTo(padL, padT + h)
      ..close();
    canvas.drawPath(
      myFill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.28),
            const Color(0xFFFF6B35).withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, padT, size.width, h)),
    );
    canvas.drawPath(
      myPath,
      Paint()
        ..color = const Color(0xFFFF6B35)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── dots on my line ──
    for (int i = 0; i < n; i++) {
      final cx = xOf(i);
      final cy = yOf(myPoints[i]);
      canvas.drawCircle(
          Offset(cx, cy), 5, Paint()..color = const Color(0xFFFF6B35));
      canvas.drawCircle(
          Offset(cx, cy),
          5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    // ── x labels ──
    for (int i = 0; i < xLabels.length; i++) {
      _drawText(
        canvas,
        xLabels[i],
        Offset(xOf(i) - 14, size.height - padB + 4),
        const TextStyle(fontSize: 9, color: Color(0xFF90A4AE)),
        width: 28,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style,
      {double width = 40}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) =>
      old.myPoints != myPoints ||
          old.avgPoints != avgPoints ||
          old.xLabels != xLabels;
}

// ══════════════════════════════════════════════════
//  Ranking Card
// ══════════════════════════════════════════════════
class _RankingCard extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final int percent;

  const _RankingCard({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
                const SizedBox(height: 3),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          // percent badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$percent%',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Comment Card
// ══════════════════════════════════════════════════
class _CommentCard extends StatelessWidget {
  final String comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final hasComment = comment.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C5C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 20, color: Color(0xFF0F4C5C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor Comment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasComment ? comment : 'ยังไม่มีคอมเมนต์จากอาจารย์',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: hasComment ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Legend Dot
// ══════════════════════════════════════════════════
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