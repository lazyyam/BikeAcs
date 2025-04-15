import 'dart:convert';

import 'package:http/http.dart' as http;

class PaymentService {
  static const String _apiKey = '86411f44-009c-4da6-bd02-273d98c20c8d';
  static const String _collectionId = 'ykpgj_ea';

  static Future<String?> createBill({
    required String name,
    required String email,
    required int amountInCents,
  }) async {
    final url = Uri.parse('https://www.billplz-sandbox.com/api/v3/bills');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'collection_id': _collectionId,
        'name': name,
        'email': email,
        'amount': amountInCents,
        'description': 'BikeAcs Order Payment',
        'callback_url': 'https://yourapp.com/callback',
        'redirect_url': 'https://yourapp.com/payment-complete?x-success=true',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      print('Error creating bill: ${response.body}');
      return null;
    }
  }

  // static Future<void> openBillUrl(String url) async {
  //   final uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  Future<String?> getBillStatus(String billId) async {
    final url =
        Uri.parse('https://www.billplz-sandbox.com/api/v3/bills/$billId');

    final response = await http.get(
      url,
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('86411f44-009c-4da6-bd02-273d98c20c8d:'))}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['paid'] ? "Paid" : "Unpaid";
    } else {
      print("Error checking status: ${response.body}");
      return null;
    }
  }
}
