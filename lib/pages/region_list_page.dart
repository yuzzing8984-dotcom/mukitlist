import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'restaurant_list_page.dart';

class RegionListPage extends StatefulWidget {
  const RegionListPage({super.key});

  @override
  State<RegionListPage> createState() => _RegionListPageState();
}

class _RegionListPageState extends State<RegionListPage> {
  String _query = '';

  // 네가 쓰던 지역 목록 그대로 쓰면 됨 (추가/수정 가능)
  final List<String> _regions = const [
    '서울',
    '경기',
    '부산',
    '제주',
    '강원',
    '충청',
    '전라',
    '경상',
  ];

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();

    final visibleRegions = _regions
        .where((r) => q.isEmpty ? true : r.contains(q))
        .toList();

    // ✅ Hive 박스
    final box = Hive.box<Restaurant>('restaurants');

    return Scaffold(
      appBar: AppBar(title: const Text('먹킷리스트')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '지역 검색(예: 서울)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),

          /// ✅ 박스 변화(추가/삭제/수정)될 때마다 지역별 카운트 자동 갱신
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<Restaurant> b, _) {
              print(b.values.map((e) => e.region).toList());

                // region -> count
                final Map<String, int> counts = {};
                for (final r in b.values) {
                  counts[r.region] = (counts[r.region] ?? 0) + 1;
                }

                return ListView.separated(
                  itemCount: visibleRegions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final region = visibleRegions[index];
                    final count = counts[region] ?? 0;

                    return ListTile(
                      title: Text(region),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ 개수 표시(칩 느낌)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantListPage(region: region),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
