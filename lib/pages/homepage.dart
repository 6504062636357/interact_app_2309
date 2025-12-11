import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _futureDashboard;

  @override
  void initState() {
    super.initState();
    _futureDashboard = ApiService.getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureDashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final data = snapshot.data!;
            final user = data["user"];
            final hotCourse = data["hotCourse"];
            final learningPlan = List.from(data["learningPlan"]);
            final announcement = data["announcement"];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hi, ${user['name']}", style: const TextStyle(fontSize: 24)),
                  Text("Today: ${user['learnedToday']} / ${user['goalMinutes']} minutes"),
                  const SizedBox(height: 20),

                  Text("🔥 Hot Course"),
                  Card(
                    child: ListTile(
                      leading: Image.network(hotCourse["imageUrl"]),
                      title: Text(hotCourse["title"]),
                      subtitle: Text(hotCourse["description"]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text("📘 Learning Plan"),
                  ...learningPlan.map((lp) => ListTile(
                    title: Text(lp["title"]),
                    subtitle: Text("Progress: ${lp["progress"]}"),
                  )),

                  const SizedBox(height: 20),
                  Text("📢 Announcement"),
                  Card(
                    child: ListTile(
                      leading: Image.network(announcement["bannerUrl"]),
                      title: Text(announcement["title"]),
                      subtitle: Text(announcement["subtitle"]),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
