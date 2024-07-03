import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ApiService {
  static const int maxRetries = 5; // Max number of retries
  static const int baseDelay = 500; // Base delay in milliseconds

  static Future<http.Response> fetchMatchImage(String imageId, {int retries = 0}) async {
    final url = 'https://cricbuzz-cricket.p.rapidapi.com/img/v1/i1/c$imageId/i.jpg';
    final headers = {
      'x-rapidapi-key': '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859',
      'x-rapidapi-host': 'cricbuzz-cricket.p.rapidapi.com'
    };
    final response = await http.get(Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/widgets/falcon.jpg'));
    return response;
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 429 && retries < maxRetries) {
        // Rate limited, wait and retry
        final delay = baseDelay * (2 ^ retries); // Exponential backoff
        await Future.delayed(Duration(milliseconds: delay));
        return fetchMatchImage(imageId, retries: retries + 1); // Retry
      } else {
        throw Exception('Failed to fetch image: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to fetch image: $error');
    }
  }
}
