import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // -------------------------
  // สร้างห้องแชท
  // -------------------------
  Future<String> createChatRoom(String otherUserId) async {
    final roomRef = await _db.collection('chat_rooms').add({
      'users': [currentUid, otherUserId],
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return roomRef.id;
  }

  // -------------------------
  // ส่งข้อความ
  // -------------------------
  Future<void> sendMessage(
      String roomId, String content, String type) async {

    final msgData = {
      'senderId': currentUid,
      'text': type == 'text' ? content : '',
      'imageUrl': type == 'image' ? content : '',
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // เพิ่มข้อความ
    await _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add(msgData);

    // update last message
    await _db.collection('chat_rooms').doc(roomId).update({
      'lastMessage': type == 'text' ? content : '📷 ส่งรูปภาพ',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------------
  // ดึงข้อความ realtime
  // -------------------------
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  // -------------------------
  // ดึงห้องแชทของ user
  // -------------------------
  Stream<QuerySnapshot> getUserChatRooms() {
    return _db
        .collection('chat_rooms')
        .where('users', arrayContains: currentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}