import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D6D), // พื้นหลังสีน้ำเงินเข้มให้เข้ากับธีมหลัก
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ส่วนหัวของหน้า Message ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Messages",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // --- ส่วนรายการข้อความ (พื้นหลังขาวขอบมน) ---
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 20),
                  children: [
                    _buildChatTile(
                      name: "Teacher Anne",
                      message: "อย่าลืมเข้าเรียนวิชา English วันนี้นะคะ!",
                      time: "10:30 AM",
                      unreadCount: 2,
                      avatarColor: Colors.pink.shade100,
                    ),
                    _buildChatTile(
                      name: "Dr. Galaxy",
                      message: "โปรเจกต์ Space Exploration ยอดเยี่ยมมากครับ",
                      time: "Yesterday",
                      unreadCount: 0,
                      avatarColor: Colors.deepPurple.shade100,
                    ),
                    _buildChatTile(
                      name: "System Support",
                      message: "คุณได้ทำการจองคอร์ส Robotics สำเร็จแล้ว",
                      time: "2 Mar",
                      unreadCount: 0,
                      avatarColor: Colors.blueGrey.shade100,
                    ),
                    _buildChatTile(
                      name: "Nguyen Shane",
                      message: "เอกสารประกอบการเรียน Java อยู่ในกลุ่มนะครับ",
                      time: "1 Mar",
                      unreadCount: 5,
                      avatarColor: Colors.orange.shade100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างแถบข้อความแต่ละคน
  Widget _buildChatTile({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required Color avatarColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: avatarColor,
        child: Text(
          name[0], // ดึงตัวอักษรแรกมาทำเป็น Avatar
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black54),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.orange, // สีส้มตามธีมแอป
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () {
        // จัดการเมื่อกดที่แชท
      },
    );
  }
}