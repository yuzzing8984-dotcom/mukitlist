import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverLocalItem {
  final String title;        // HTML <b> 태그 포함
  final String roadAddress;
  final String address;
  final String link;
  final double lat;          // 위도
  final double lng;          // 경도

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
      throw Exception('Naver search failed: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    return items.map((e) {
      // 네이버 local api의 mapx/mapy는 보통 TM128 좌표로 내려오는 케이스가 많아서
      // 1) 이 값이 위경도인지 확실하지 않으면, 일단 "좌표 변환"이 필요할 수 있음.
      // 2) 그런데 어떤 경우엔 위경도처럼 보이는 값이 오기도 해서,
      //    우선은 '좌표는 나중에 확정'하고, 지금은 결과 파싱부터 붙여두자.
      //
      // ✅ 우선 파싱: 숫자 형태만 잡아두고,
      // AddRestaurantPage에서 "좌표 변환 필요 여부"를 확인해줄게.
      final mapx = (e['mapx'] ?? '').toString();
      final mapy = (e['mapy'] ?? '').toString();

      double safeParse(String v) => double.tryParse(v) ?? 0;

      return NaverLocalItem(
        title: (e['title'] ?? '').toString(),
        roadAddress: (e['roadAddress'] ?? '').toString(),
        address: (e['address'] ?? '').toString(),
        link: (e['link'] ?? '').toString(),
        lng: safeParse(mapx),
        lat: safeParse(mapy),
      );
    }).toList();
  }
}
