import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart'; // ตรวจสอบ Path ให้ถูกต้อง
import '../model/course.model.dart';
import 'PaymentSuccessPage.dart';

class QRPaymentPage extends StatefulWidget {
  final CourseModel course;
  const QRPaymentPage({super.key, required this.course});

  @override
  State<QRPaymentPage> createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends State<QRPaymentPage> {
  bool _isLoading = false;

  // ฟังก์ชันจำลองการยืนยันว่าจ่ายเงินแล้วจริงๆ และบันทึกลง DB
  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);

    try {
      // 1. เรียก API ไปที่ Backend เพื่อสร้างรายการ Payment (สถานะสำเร็จ)
      // หมายเหตุ: คุณต้องมี Route นี้ที่ฝั่ง Backend ด้วยนะครับ
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments/qr'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "course": widget.course.id,
          "amount": widget.course.price,
          "status": "successful", // บังคับเป็นสำเร็จเพื่อให้ Demo ผ่าน
          "method": "QR"
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final payment = data['payment'];

        String? paymentId;

        if (payment != null && payment is Map && payment['_id'] != null) {
          paymentId = payment['_id'].toString();
        }
        print("FULL DATA: $data");
        print("PAYMENT: $payment");
        print("PAYMENT ID: $paymentId");

        if (mounted && paymentId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                course: widget.course,
                paymentId: paymentId, // ส่งเลข ID ที่ดึงได้จริงไป
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text("Scan QR to Pay", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Image.network("https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=payment", width: 200),
            const SizedBox(height: 20),
            Text("Course: ${widget.course.title}"),
            Text("Amount: ${widget.course.price} THB"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // ถ้ากำลังโหลดให้กดไม่ได้
                onPressed: _isLoading ? null : () => _confirmPayment(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("I've Paid", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}