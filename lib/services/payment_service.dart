import 'package:omise_flutter/omise_flutter.dart';

class PaymentService {

  static Future<String> createToken(dynamic OmiseFlutter) async {

    final token = await OmiseFlutter.instance.createToken(

      name: "Test User",

      number: "4242424242424242",

      expirationMonth: 12,

      expirationYear: 2030,

      securityCode: "123",

    );

    return token.id;

  }

}