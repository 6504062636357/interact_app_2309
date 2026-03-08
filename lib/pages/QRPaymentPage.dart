import 'package:flutter/material.dart';
import '../model/course.model.dart';
import 'PaymentSuccessPage.dart';

class QRPaymentPage extends StatelessWidget {

  final CourseModel course;

  const QRPaymentPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("QR Payment"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height: 30),

            Text(
              "Scan QR to Pay",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 30),

            /// QR Code
            Image.network(
              "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=payment",
              width: 200,
            ),

            const SizedBox(height: 20),

            Text("Course: ${course.title}"),

            Text("Amount: ${course.price} THB"),

            const Spacer(),

            ElevatedButton(

              onPressed: () {

                Navigator.pushReplacement(

                  context,

                  MaterialPageRoute(

                    builder: (_) => PaymentSuccessPage(course: course),

                  ),

                );

              },

              child: const Text("I've Paid"),

            )

          ],

        ),

      ),

    );

  }

}