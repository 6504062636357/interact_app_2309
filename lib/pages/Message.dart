import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {

  String get currentUserId =>
      FirebaseAuth.instance.currentUser!.uid;

  bool isNotiTab = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFFD700),

      appBar: AppBar(
        title: const Text(
          "Notification",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [

          IconButton(
            icon: const Icon(Icons.person_add_alt_1,
                color: Colors.black),
            onPressed: () => _searchAndStartChat(context),
          )

        ],
      ),

      body: Column(
        children: [

          _buildTabs(),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30)),
              ),
              child: isNotiTab
                  ? _buildChatList()
                  : const Center(
                  child: Text("No message content")),
            ),
          ),

        ],
      ),
    );
  }

  /// TAB
  Widget _buildTabs() {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          GestureDetector(
            onTap: () => setState(() => isNotiTab = true),
            child: _buildTabItem("notification",
                isActive: isNotiTab),
          ),

          const SizedBox(width: 40),

          GestureDetector(
            onTap: () => setState(() => isNotiTab = false),
            child: _buildTabItem("message",
                isActive: !isNotiTab),
          ),

        ],
      ),
    );
  }

  /// CHAT LIST
  Widget _buildChatList() {

    return StreamBuilder<QuerySnapshot>(

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
              child: Text("No conversations found"));
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
                      userData['displayName'] ?? "No Name";
                }

                Timestamp? time =
                room['updatedAt'] is Timestamp
                    ? room['updatedAt']
                    : null;

                return _buildChatTile(
                    context,
                    roomId,
                    name,
                    room['lastMessage'] ?? "",
                    time);
              },
            );
          },
        );
      },
    );
  }

  /// SEARCH USER
  void _searchAndStartChat(BuildContext context) async {

    TextEditingController searchCtrl =
    TextEditingController();

    var myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    String myRole = myDoc['role'];

    String targetRole =
    myRole == "student" ? "teacher" : "student";

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text("Start New Chat"),

        content: TextField(
          controller: searchCtrl,
          decoration:
          const InputDecoration(hintText: "Enter name"),
        ),

        actions: [

          TextButton(

            child: const Text("Chat"),

            onPressed: () async {

              String targetName =
              searchCtrl.text.trim();

              var query = await FirebaseFirestore
                  .instance
                  .collection('users')
                  .where('displayName',
                  isEqualTo: targetName)
                  .where('role',
                  isEqualTo: targetRole)
                  .get();

              if (query.docs.isEmpty) {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                      content: Text("User not found")),
                );

                return;
              }

              String targetUid =
                  query.docs.first.id;

              if (targetUid == currentUserId) return;

              List<String> ids = [
                currentUserId,
                targetUid
              ]..sort();

              String roomId = ids.join("_");

              await FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(roomId)
                  .set({

                'participants': ids,
                'updatedAt':
                FieldValue.serverTimestamp(),
                'lastMessage': '',

              }, SetOptions(merge: true));

              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    roomId: roomId,
                    partnerName: targetName,
                  ),
                ),
              );
            },
          )

        ],
      ),
    );
  }

  /// CHAT TILE
  Widget _buildChatTile(
      BuildContext context,
      String roomId,
      String name,
      String lastMsg,
      Timestamp? time) {

    return Container(

      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 5)
        ],
      ),

      child: ListTile(

        leading:
        const CircleAvatar(child: Icon(Icons.person)),

        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.bold)),

        subtitle: Text(lastMsg,
            maxLines: 1),

        trailing: ElevatedButton(

          onPressed: () {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
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
  }

  Widget _buildTabItem(
      String label,
      {required bool isActive}) {

    return Column(
      children: [

        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isActive
                    ? FontWeight.bold
                    : FontWeight.normal)),

        if (isActive)
          Container(
            margin:
            const EdgeInsets.only(top: 4),
            height: 2,
            width: 30,
            color: Colors.black,
          ),
      ],
    );
  }
}