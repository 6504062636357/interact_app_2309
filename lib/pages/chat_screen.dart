import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _messageController = TextEditingController();

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? "";

  /// ส่งข้อความ
  Future<void> _sendText() async {

    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text.trim();

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({

      "senderId": currentUserId,
      "type": "text",
      "text": text,
      "fileUrl": "",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp()

    });

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .update({

      "lastMessage": text,
      "updatedAt": FieldValue.serverTimestamp()

    });

  }

  /// mark message ว่าอ่านแล้ว
  void markMessagesAsRead(List<QueryDocumentSnapshot> docs) {

    for (var doc in docs) {

      final data = doc.data() as Map<String, dynamic>;

      if (data['senderId'] != currentUserId &&
          (data['isRead'] ?? false) == false) {

        doc.reference.update({
          "isRead": true
        });

      }

    }

  }

  /// bubble message
  Widget _buildBubble(Map<String,dynamic> msg,bool isMe){

    Timestamp? time = msg['createdAt'];

    String formattedTime = "";

    if(time != null){

      DateTime date = time.toDate();

      formattedTime =
      "${date.hour}:${date.minute.toString().padLeft(2,'0')}";

    }

    Widget content;

    if(msg["type"]=="image"){

      content = Image.network(msg["fileUrl"],width:200);

    }else if(msg["type"]=="pdf"){

      content = const Text(
        "📄 PDF File",
        style: TextStyle(color:Colors.blue),
      );

    }else{

      content = Text(msg["text"]??"");

    }

    return Align(

      alignment:
      isMe?Alignment.centerRight:Alignment.centerLeft,

      child: Column(

        crossAxisAlignment:
        isMe?CrossAxisAlignment.end:CrossAxisAlignment.start,

        children: [

          Container(

            margin: const EdgeInsets.symmetric(vertical:5),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color:
              isMe?const Color(0xFFFFE58F):Colors.white,

              borderRadius: BorderRadius.circular(12),

            ),

            child: content,

          ),

          Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                formattedTime,

                style: const TextStyle(
                    fontSize:11,
                    color:Colors.grey),

              ),

              const SizedBox(width:6),

              if(isMe)

                Text(

                  (msg['isRead'] ?? false)
                      ? "✓✓"
                      : "✓",

                  style: const TextStyle(
                      fontSize:11,
                      color:Colors.grey),

                )

            ],

          )

        ],

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    if(currentUserId.isEmpty){

      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );

    }

    return Scaffold(

      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(

        backgroundColor: const Color(0xFFFFD700),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color:Colors.black),
          onPressed: ()=>Navigator.pop(context),
        ),

        centerTitle:true,

        title: Column(
          children: [
            Text(widget.partnerName,
                style: const TextStyle(
                    color:Colors.black,
                    fontSize:18,
                    fontWeight:FontWeight.bold)),
            const Text("Online",
                style: TextStyle(
                    color:Colors.black54,
                    fontSize:12))
          ],
        ),

      ),

      body: Column(

        children: [

          Expanded(

            child: StreamBuilder<QuerySnapshot>(

              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy("createdAt")
                  .snapshots(),

              builder:(context,snapshot){

                if(!snapshot.hasData){
                  return const Center(
                      child:CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                markMessagesAsRead(docs);

                return ListView.builder(

                  padding: const EdgeInsets.all(20),

                  itemCount: docs.length,

                  itemBuilder:(context,index){

                    var msg =
                    docs[index].data() as Map<String,dynamic>;

                    bool isMe =
                        msg["senderId"]==currentUserId;

                    return _buildBubble(msg,isMe);

                  },

                );

              },

            ),

          ),

          Container(

            padding: const EdgeInsets.all(10),

            color: Colors.white,

            child: Row(

              children: [

                Expanded(

                  child: TextField(

                    controller:_messageController,

                    decoration: const InputDecoration(
                      hintText:"Type a message...",
                      border:InputBorder.none,
                    ),

                  ),

                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:_sendText,
                )

              ],

            ),

          )

        ],

      ),

    );

  }

}