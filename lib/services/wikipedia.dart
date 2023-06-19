import 'dart:convert';
import 'package:http/http.dart' as http;

// Magnus tool random article uri.host: 'tools.wmflabs.org'
// Wikipedia uri.host: 'en.wikipedia.org'

class Wikipedia {
  // static Future<Uri> getRandomArticle() async {}

  static Future<int?> getPageId(String title) async {
    // https://en.wikipedia.org/w/api.php?action=query&titles=<title>&format=json
    Uri uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'titles': title,
      'format': 'json',
    });

    var response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to get page id');
    }

    var body = jsonDecode(response.body) as Map<String, dynamic>;

    return int.parse(body['query']['pages'].keys.first);
  }
}
