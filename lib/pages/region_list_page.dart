import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'add_restaurant_page.dart';

class RegionListPage extends StatelessWidget {
  final void Function(dynamic key) onSelectRestaurantKey;

  const RegionListPage({
    super.key,
    required this.onSelectRestaurantKey,
  });

  Future<void> _openAdd(BuildContext context) async {
    final result = await Navigator.push<Restaurant>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRestaurantPage(),
      ),
    );

    if (result == null) return;

    final box = Hive.box<Restaurant>('restaurants');
    await box.add(result);
  }

  Map<String, List<MapEntry<dynamic, Restaurant>>> _groupByRegion(
      Box<Restaurant> box,
      ) {
    final Map<String, List<MapEntry<dynamic, Restaurant>>> grouped = {};

    for (final key in box.keys) {
      final r = box.get(key);
      if (r == null) continue;

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
          if (b.isEmpty) {
            return const Center(child: Text('저장된 맛집이 없어요'));
          }

          final grouped = _groupByRegion(b);
          final regions = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final region = regions[index];
              final items = grouped[region]!;

              return ExpansionTile(
                title: Text(region, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${items.length}곳'),
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
                      title: Text(r.name),
                      subtitle: Text(r.district),
                      onTap: () => onSelectRestaurantKey(key),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
