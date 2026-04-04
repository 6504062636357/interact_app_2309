import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../model/course.model.dart';
import 'PaymentSuccessPage.dart';
import 'package:flutter_svg/flutter_svg.dart';
class PaymentPage extends StatefulWidget {
  final CourseModel course;

  const PaymentPage({super.key, required this.course});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String paymentMethod = "promptpay";

  String qrUrl = "";
  String chargeId = "";
  String paymentStatus = "";
  bool loading = false;
  bool isCreatingPayment = false;
  String? paymentId;
  Timer? statusTimer;
  Timer? countdownTimer;

  // นับถอยหลัง 5 นาที = 300 วินาที
  int remainingSeconds = 300;

  @override
  void dispose() {
    statusTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  /// ===============================
  /// CREATE PAYMENT
  /// ===============================
  Future<void> createPayment() async {
    try {
      setState(() {
        loading = true;
        isCreatingPayment = true;
        qrUrl = "";
        chargeId = "";
        paymentStatus = "";
        remainingSeconds = 300;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Please login first");
      }

      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments/create'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "courseId": widget.course.id,
          "amount": widget.course.price,
          "method": paymentMethod,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data["message"] ?? "Create payment failed");
      }

      // ถ้าเป็น PromptPay ให้เอา QR มาแสดง
      if (paymentMethod == "promptpay") {
        /// DEBUG
        print("API RESPONSE: $data");
        print("QR URL FROM API: ${data["qr"]}");
        setState(() {
          qrUrl = data["qr"] ?? "";
          chargeId = data["chargeId"] ?? "";
          paymentStatus = data["status"] ?? "pending";
        });

        if (data["payment"] != null) {
          paymentId = data["payment"]["_id"].toString();
          print("DEBUG: paymentId has been set to -> $paymentId");
        }

        if (chargeId.isNotEmpty) {
          startCheckStatus();
          startCountdown();
        }
      } else {
        // ถ้าเป็น card ในตัวอย่างนี้ให้ถือว่าสำเร็จและไปหน้า success
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(course: widget.course),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
        isCreatingPayment = false;
      });
    }
  }

  /// ===============================
  /// CHECK PAYMENT STATUS
  /// เช็คทุก 3 วินาที
  /// ===============================
  void startCheckStatus() {
    statusTimer?.cancel();

    statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        if (chargeId.isEmpty) return;

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final token = await user.getIdToken();

        final res = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/payments/status/$chargeId'),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        final data = jsonDecode(res.body);

        if (res.statusCode == 200) {
          final status = data["status"] ?? "";

          if (!mounted) return;

          setState(() {
            paymentStatus = status;
          });

          if (status == "successful" || status == "success") {
            timer.cancel();
            countdownTimer?.cancel();

            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentSuccessPage(course: widget.course,paymentId: paymentId,),
              ),
            );
          }
        }
      } catch (_) {
        // ไม่เด้ง error ถี่ ๆ ระหว่าง polling
      }
    });
  }

  /// ===============================
  /// COUNTDOWN 5 นาที
  /// ===============================
  void startCountdown() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (remainingSeconds <= 0) {
        timer.cancel();
        statusTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR payment expired. Please try again.")),
        );

        setState(() {
          print("QR URL IN STATE: $qrUrl");
          chargeId = "";
          paymentStatus = "expired";
          
        });

        return;
      }

      setState(() {
        remainingSeconds--;
      });
    });
  }

  /// ===============================
  /// REFRESH QR ใหม่
  /// ===============================
  Future<void> refreshQr() async {
    statusTimer?.cancel();
    countdownTimer?.cancel();
    await createPayment();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$sec";
  }

  Widget buildPaymentLogos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _logoBox('assets/payment/promptpay.png'),
        _logoBox('assets/payment/kplus.png'),
        _logoBox('assets/payment/truemoney.png'),
      ],
    );
  }

  Widget _logoBox(String assetPath) {
    return Container(
      width: 58,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Text(
              "Logo",
              style: TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showQr = paymentMethod == "promptpay" && qrUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B5870),
        elevation: 0,
        title: const Text(
          "Payment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xff0B5870),
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Column(
                children: [
                  Text(
                    "\$${widget.course.price}",
                    style: const TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xffF3F6FA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: isCreatingPayment
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : showQr
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: SvgPicture.memory(
                                        base64Decode(qrUrl.split(',').last),
                                        fit: BoxFit.contain,
                                      )
                            //
                            //
                            // Image.network(
                                      //   qrUrl,
                                      //   fit: BoxFit.contain,
                                      //   errorBuilder: (_, __, ___) {
                                      //     return const Center(
                                      //       child: Text("Unable to load QR"),
                                      //     );
                                      //   },
                                      // ),
                                    )
                                  : Center(
                                      child: Text(
                                        paymentMethod == "promptpay"
                                            ? "Press Confirm to generate QR"
                                            : "Press Confirm to continue with card payment",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          paymentMethod == "promptpay"
                              ? "Scan this QR code to pay"
                              : "Credit card payment will continue after confirm",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildPaymentLogos(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: "promptpay",
                            groupValue: paymentMethod,
                            activeColor: const Color(0xff6C55C6),
                            title: const Text(
                              "PromptPay QR",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onChanged: loading
                                ? null
                                : (value) {
                                    setState(() {
                                      paymentMethod = value!;
                                      qrUrl = "";
                                      chargeId = "";
                                      paymentStatus = "";
                                      remainingSeconds = 300;
                                    });
                                  },
                          ),
                          RadioListTile<String>(
                            value: "card",
                            groupValue: paymentMethod,
                            activeColor: const Color(0xff6C55C6),
                            title: const Text(
                              "Credit Card",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onChanged: loading
                                ? null
                                : (value) {
                                    setState(() {
                                      paymentMethod = value!;
                                      qrUrl = "";
                                      chargeId = "";
                                      paymentStatus = "";
                                      remainingSeconds = 300;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payment Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.course.instructor,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (paymentMethod == "promptpay" && chargeId.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Status",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  paymentStatus.isEmpty ? "pending" : paymentStatus,
                                  style: TextStyle(
                                    color: paymentStatus == "successful"
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (paymentMethod == "promptpay" && chargeId.isNotEmpty)
                            const SizedBox(height: 12),
                          if (paymentMethod == "promptpay" && chargeId.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "QR Expires In",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  formatTime(remainingSeconds),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Cost",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "\$${widget.course.price}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (paymentMethod == "promptpay" && chargeId.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loading ? null : refreshQr,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Refresh QR"),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 70,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xffFF4A3D),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF9800),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: loading ? null : createPayment,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.6,
                                  ),
                                )
                              : const Text(
                                  "Confirm",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
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
}