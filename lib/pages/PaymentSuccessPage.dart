import 'package:flutter/material.dart';

import '../model/course.model.dart';
import 'BookingPage.dart';

class PaymentSuccessPage extends StatefulWidget {
  final CourseModel course;

  const PaymentSuccessPage({super.key, required this.course});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B5870),
        elevation: 0,
        title: const Text("Payment"),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Payment Successful!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your payment has been processed successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                          "Booking Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.course.instructor,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Amount",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "\$${widget.course.price}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF9800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingPage(course: widget.course),
                                ),
                              );
                            },
                            child: const Text(
                              "View Booking",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}