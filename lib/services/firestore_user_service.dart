import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> syncUserToFirestore({
  required String name,
  required String role,
}) async {

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({

    'displayName': name,
    'role': role,
    'authUid': user.uid,
    'photoUrl': "",
    'lastActive': FieldValue.serverTimestamp(),

  }, SetOptions(merge: true));
}