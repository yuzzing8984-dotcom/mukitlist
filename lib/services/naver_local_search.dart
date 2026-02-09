import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverLocalItem {
  final String title;
  final String roadAddress;
  final String address;
  final String link;

  // 네이버 local api의 mapx/mapy (TM128 가능)
  final double lat;
  final double lng;

  NaverLocalItem({
    required this.title,
    required this.roadAddress,
    required this.address,
    required this.link,
    required this.lat,
    required this.lng,
  });

  String get cleanTitle =>
      title.replaceAll('<b>', '').replaceAll('</b>', '');
}

class NaverLocalSearchService {
  final String clientId;
  final String clientSecret;

  NaverLocalSearchService({
    required this.clientId,
    required this.clientSecret,
  });

  Future<List<NaverLocalItem>> search(String query, {int display = 10}) async {
    final uri = Uri.https(
      'openapi.naver.com',
      '/v1/search/local.json',
      {
        'query': query,
        'display': '$display',
      },
    );

    final res = await http.get(
      uri,
      headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Naver search failed: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    final result = <NaverLocalItem>[];

    for (final e in items) {
      final mapxStr = (e['mapx'] ?? '').toString();
      final mapyStr = (e['mapy'] ?? '').toString();

      final x = double.tryParse(mapxStr);
      final y = double.tryParse(mapyStr);

      // 좌표 없거나 이상하면 스킵
      if (x == null || y == null || x == 0 || y == 0) continue;

      result.add(
        NaverLocalItem(
          title: (e['title'] ?? '').toString(),
          roadAddress: (e['roadAddress'] ?? '').toString(),
          address: (e['address'] ?? '').toString(),
          link: (e['link'] ?? '').toString(),
          lng: x, // TM128 X
          lat: y, // TM128 Y
        ),
      );
    }

    return result;
  }
}
