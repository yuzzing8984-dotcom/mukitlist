import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverLocalItem {
  final String title;
  final String roadAddress;
  final String address;
  final String link;

  // ✅ 네이버 Local API 원본 좌표 (TM128)
  final double mapx; // X
  final double mapy; // Y

  NaverLocalItem({
    required this.title,
    required this.roadAddress,
    required this.address,
    required this.link,
    required this.mapx,
    required this.mapy,
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
      throw Exception('Naver search failed: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    final result = <NaverLocalItem>[];

    for (final e in items) {
      final mapxStr = (e['mapx'] ?? '').toString();
      final mapyStr = (e['mapy'] ?? '').toString();

      final mapx = double.tryParse(mapxStr) ?? 0;
      final mapy = double.tryParse(mapyStr) ?? 0;

      // 좌표 없으면 스킵
      if (mapx == 0 || mapy == 0) continue;

      result.add(
        NaverLocalItem(
          title: (e['title'] ?? '').toString(),
          roadAddress: (e['roadAddress'] ?? '').toString(),
          address: (e['address'] ?? '').toString(),
          link: (e['link'] ?? '').toString(),
          mapx: mapx,
          mapy: mapy,
        ),
      );
    }

    return result;
  }
}
