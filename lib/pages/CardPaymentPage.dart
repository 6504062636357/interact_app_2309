import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../model/course.model.dart';
import 'PaymentSuccessPage.dart';

class CardPaymentPage extends StatefulWidget {

  final CourseModel course;

  const CardPaymentPage({super.key, required this.course});

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {

  final cardController = TextEditingController();
  final nameController = TextEditingController();
  final expController = TextEditingController();
  final cvcController = TextEditingController();

  bool loading = false;

  Future<void> payCard() async{

    try{

      setState(() {
        loading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      final token = await user!.getIdToken();

      /// Omise test token
      const omiseToken = "tokn_test_5f3c...";

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments/card'),
        headers:{
          "Content-Type":"application/json",
          "Authorization":"Bearer $token"
        },
        body: jsonEncode({
          "courseId": widget.course.id,
          "amount": widget.course.price,
          "token": omiseToken
        }),
      );

      if(response.statusCode == 200){

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(course: widget.course),
          ),
        );

      }

    }catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()))
      );

    }

    setState(() {
      loading = false;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Card Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: cardController,
              decoration: const InputDecoration(labelText: "Card Number"),
            ),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            TextField(
              controller: expController,
              decoration: const InputDecoration(labelText: "MM/YY"),
            ),

            TextField(
              controller: cvcController,
              decoration: const InputDecoration(labelText: "CVC"),
            ),

            const SizedBox(height:20),

            ElevatedButton(
              onPressed: loading ? null : payCard,
              child: const Text("Pay"),
            )

          ],
        ),
      ),
    );
  }
}