import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String serviceId = 'service_s9ss37t';
  static const String templateId = 'template_xhb4hvf';
  static const String publicKey = 'Hbkpaqq9UfoJwcqsu';

  static Future<bool> sendEmail({
  required String toEmail,
  required String name,
  required String homestay,
  required String status,
  required String checkIn,
  required String checkOut,
}) async {
  const String url = "https://api.emailjs.com/api/v1.0/email/send";

  final body = jsonEncode({
    "service_id": serviceId,
    "template_id": templateId,
    "user_id": publicKey,
    "template_params": {
      "to_email": toEmail,
      "user_name": name,
      "homestay": homestay,
      "status": status,
      "check_in": checkIn,
      "check_out": checkOut,
    }
  });

  final response = await http.post(
    Uri.parse(url),
    headers: {
      
      "Content-Type": "application/json",
    },
    body: body,
  );
  print('EmailJS status: ${response.statusCode}');
  print('EmailJS response: ${response.body}');

  return response.statusCode == 200;
}
}