import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'add_restaurant_page.dart';
import 'restaurant_detail_page.dart';

class RestaurantListPage extends StatefulWidget {
  final String region;
  const RestaurantListPage({super.key, required this.region});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  String _query = '';
  String _selectedDistrict = '전체';

  Box<Restaurant> get _box => Hive.box<Restaurant>('restaurants');

  @override
  Widget build(BuildContext context) {
    final region = widget.region;

    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (context, Box<Restaurant> box, _) {
        // 1) 지역 목록
        final regionItems =
            box.values.where((e) => e.region == region).toList();

        // 2) 드롭다운 옵션
        final districts = <String>{
          '전체',
          ...regionItems.map((e) => e.district),
        }.toList();

        // 현재 선택된 동네가 목록에서 사라졌으면 '전체'로 리셋
        if (!districts.contains(_selectedDistrict)) {
          _selectedDistrict = '전체';
        }

        // 3) 검색/필터
        final q = _query.trim();
        final filtered = regionItems.where((e) {
          final matchQuery = q.isEmpty ||
              e.name.contains(q) ||
              e.district.contains(q) ||
              e.memo.contains(q);

          final matchDistrict =
              _selectedDistrict == '전체' || e.district == _selectedDistrict;

          return matchQuery && matchDistrict;
        }).toList();

        // ✅ AppBar 타이틀: 전체면 (총개수), 필터중이면 (filtered/total)
        final title = (filtered.length == regionItems.length)
            ? '$region 맛집 (${regionItems.length})'
            : '$region 맛집 (${filtered.length}/${regionItems.length})';

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Column(
            children: [
              // ✅ 검색 + 드롭다운 한 줄 레이아웃
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: '맛집/동네/메모 검색',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: districts
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedDistrict = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          (q.isEmpty && _selectedDistrict == '전체')
                              ? '$region에 저장된 맛집이 없어요.\n오른쪽 아래 +로 추가해보자!'
                              : '검색 결과가 없어요 😢',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = filtered[index];

                          return ListTile(
                            title: Text(r.name),
                            subtitle: Text(r.district),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final removed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantDetailPage(restaurant: r),
                                ),
                              );

                              if (removed == true) {
                                // ✅ Hive에서 삭제
                                final keyToDelete = box.keys.firstWhere(
                                  (k) => box.get(k) == r,
                                  orElse: () => null,
                                );
                                if (keyToDelete != null) {
                                  await box.delete(keyToDelete);
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final created = await Navigator.push<Restaurant>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRestaurantPage(region: region),
                ),
              );

              if (created != null) {
                await box.add(created); // ✅ Hive 저장
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${created.name} 저장 완료!')),
                  );
                }
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
