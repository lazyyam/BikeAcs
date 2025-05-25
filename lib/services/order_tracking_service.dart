import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderTrackingService {
  Future<void> createTracking(String trackingNumber, String courierCode) async {
    const apiKey =
        'asat_2728566750c141a1ba19796df3edf358'; // Replace with your AfterShip API Key
    const apiUrl = 'https://api.aftership.com/v4/trackings';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'aftership-api-key': apiKey,
      },
      body: jsonEncode({
        'tracking': {
          'tracking_number': trackingNumber,
          'slug': courierCode, // e.g., 'poslaju'
        }
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 409) {
      // 201 = created, 409 = already exists (OK for re-tracking)
      print('Tracking created or already exists.');
    } else {
      throw Exception('Failed to create tracking: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchTrackingStatus(
      String trackingNumber, String courierCode) async {
    const apiKey =
        'asat_2728566750c141a1ba19796df3edf358'; // Replace with your AfterShip API Key
    final url =
        'https://api.aftership.com/v4/trackings/$courierCode/$trackingNumber';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'aftership-api-key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Debug log to inspect the API response
      print('API Response: $data');

      // Check if the expected keys exist in the response
      if (data['data'] != null && data['data']['tracking'] != null) {
        return data['data']['tracking'];
      } else {
        throw Exception('Unexpected API response: Missing tracking data');
      }
    } else {
      // Debug log for failed responses
      print('Failed to fetch tracking status: ${response.body}');
      throw Exception('Failed to fetch tracking status: ${response.body}');
    }
  }
}
