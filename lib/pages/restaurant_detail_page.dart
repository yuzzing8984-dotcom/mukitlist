import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('삭제할까?'),
                  content: const Text('이 맛집을 목록에서 삭제합니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                Navigator.pop(context, true); // ✅ 리스트에서 제거하라고 신호
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: '지역', value: restaurant.region),
            const SizedBox(height: 8),
            _InfoRow(label: '동네', value: restaurant.district),
            const SizedBox(height: 16),
            const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // ✅ 메모 박스(여기서 Container 끝!)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                restaurant.memo.trim().isEmpty ? '메모 없음' : restaurant.memo,
              ),
            ),

            const Spacer(),

            // ✅ 지도 버튼(Container 밖!)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final query =
                      '${restaurant.name} ${restaurant.district} ${restaurant.region}';
                  await openMapSearch(query);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('지도에서 검색하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

Future<void> openMapSearch(String query) async {
  final encoded = Uri.encodeComponent(query);

  // 안드로이드 지도앱(geo:) 우선 시도
  final geoUri = Uri.parse('geo:0,0?q=$encoded');

  // 실패하면 웹 구글지도
  final webUri =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

  if (await canLaunchUrl(geoUri)) {
    await launchUrl(geoUri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
