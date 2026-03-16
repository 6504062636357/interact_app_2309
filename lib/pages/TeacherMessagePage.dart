import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class TeacherMessagePage extends StatefulWidget {
  const TeacherMessagePage({super.key});

  @override
  State<TeacherMessagePage> createState() =>
      _TeacherMessagePageState();
}

class _TeacherMessagePageState
    extends State<TeacherMessagePage> {

  String get currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFFD700),

      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Container(

        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(30)),
        ),

        child: StreamBuilder<QuerySnapshot>(

          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('participants',
              arrayContains: currentUserId)
              .orderBy('updatedAt', descending: true)
              .snapshots(),

          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text("No conversations yet"),
              );
            }

            return ListView.builder(

              padding: const EdgeInsets.all(20),

              itemCount: docs.length,

              itemBuilder: (context, index) {

                var room =
                docs[index].data() as Map<String, dynamic>;

                String roomId = docs[index].id;

                List participants =
                    room['participants'] ?? [];

                String otherUserId =
                participants.firstWhere(
                      (id) => id != currentUserId,
                  orElse: () => "",
                );

                if (otherUserId.isEmpty) {
                  return const SizedBox();
                }

                return FutureBuilder<DocumentSnapshot>(

                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),

                  builder: (context, userSnap) {

                    String name = "Loading...";

                    if (userSnap.hasData &&
                        userSnap.data!.exists) {

                      var userData =
                      userSnap.data!.data()
                      as Map<String, dynamic>;

                      name =
                          userData['displayName'] ??
                              "No Name";
                    }

                    Timestamp? time =
                    room['updatedAt'] is Timestamp
                        ? room['updatedAt']
                        : null;

                    String formattedTime = "";

                    if (time != null) {
                      DateTime date = time.toDate();
                      formattedTime =
                      "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return Container(

                      margin:
                      const EdgeInsets.only(bottom: 15),

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5)
                        ],
                      ),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),

                        title: Text(
                          name,
                          style: const TextStyle(
                              fontWeight:
                              FontWeight.bold),
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                                room['lastMessage'] ?? "",
                                maxLines: 1),

                            const SizedBox(height: 4),

                            Text(
                              formattedTime,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey),
                            )

                          ],
                        ),

                        trailing: ElevatedButton(

                          onPressed: () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (context) =>
                                    ChatScreen(
                                      roomId: roomId,
                                      partnerName: name,
                                    ),

                              ),

                            );

                          },

                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF0D4761)),

                          child: const Text(
                            "View",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}