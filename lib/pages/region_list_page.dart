import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'add_restaurant_page.dart';

class RegionListPage extends StatefulWidget {
  final void Function(dynamic key) onSelectRestaurantKey;

  const RegionListPage({
    super.key,
    required this.onSelectRestaurantKey,
  });

  @override
  State<RegionListPage> createState() => _RegionListPageState();
}

class _RegionListPageState extends State<RegionListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAdd(BuildContext context) async {
    final result = await Navigator.push<Restaurant>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRestaurantPage(), // const 제거(안전)
      ),
    );

    if (result == null) return;

    final box = Hive.box<Restaurant>('restaurants');
    await box.add(result);
  }

  bool _matches(Restaurant r, String q) {
    if (q.isEmpty) return true;
    final qq = q.toLowerCase();

    final name = r.name.toLowerCase();
    final memo = r.memo.toLowerCase();
    final region = r.region.toLowerCase();
    final district = r.district.toLowerCase();

    // ✅ 요청: 이름, 메모, 지역 + (주소도 같이 검색되면 편함)
    return name.contains(qq) ||
        memo.contains(qq) ||
        region.contains(qq) ||
        district.contains(qq);
  }

  Map<String, List<MapEntry<dynamic, Restaurant>>> _groupByRegion(
      Iterable<MapEntry<dynamic, Restaurant>> entries,
      ) {
    final Map<String, List<MapEntry<dynamic, Restaurant>>> grouped = {};

    for (final entry in entries) {
      final key = entry.key;
      final r = entry.value;

      final region = (r.region.trim().isEmpty) ? '미지정' : r.region.trim();
      grouped.putIfAbsent(region, () => []);
      grouped[region]!.add(MapEntry(key, r));
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Restaurant>('restaurants');

    return Scaffold(
      appBar: AppBar(
        title: const Text('리스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAdd(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Restaurant> b, _) {
          // ✅ 검색창
          Widget searchBar = Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '이름 / 메모 / 지역 / 주소 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),

              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
            ),
          );

          if (b.isEmpty) {
            return Column(
              children: [
                searchBar,
                const Expanded(
                  child: Center(child: Text('저장된 맛집이 없어요')),
                ),
              ],
            );
          }

          // ✅ key까지 포함해서 가져오기
          final allEntries = b.toMap().entries.toList();

          // ✅ 검색 필터 적용
          final filtered = allEntries.where((e) => _matches(e.value, _query)).toList();

          if (filtered.isEmpty) {
            return Column(
              children: [
                searchBar,
                Expanded(
                  child: Center(
                    child: Text('“$_query” 검색 결과가 없어요'),
                  ),
                ),
              ],
            );
          }

          // ✅ 지역 그룹핑
          final grouped = _groupByRegion(filtered);
          final regions = grouped.keys.toList()..sort();

          return Column(
            children: [
              searchBar,
              Expanded(
                child: ListView.builder(
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final region = regions[index];
                    final items = grouped[region]!;

                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        '$region (${items.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),

                      children: items.map((entry) {
                        final key = entry.key;
                        final r = entry.value;

                        return Dismissible(
                          key: ValueKey('restaurant_$key'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('삭제할까요?'),
                                content: Text('“${r.name}”을(를) 삭제합니다.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await b.delete(key);
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${r.region} · ${r.district}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            onTap: () => widget.onSelectRestaurantKey(key),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
