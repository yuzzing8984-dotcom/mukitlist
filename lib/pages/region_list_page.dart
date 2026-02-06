import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'add_restaurant_page.dart';

class RegionListPage extends StatelessWidget {
  const RegionListPage({super.key});

  Future<void> _openAdd(BuildContext context) async {
    // 일단 간단히: region 직접 입력 없이 고정 region 사용 (원하면 지역 선택 UI로 바꿔줄게)
    const region = '서울';

    final result = await Navigator.push<Restaurant>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRestaurantPage(region: region),
      ),
    );

    if (result == null) return;

    final box = Hive.box<Restaurant>('restaurants');
    await box.add(result); // ✅ 여기서 저장
    // MapPage는 listenable이라 자동으로 핀이 추가됨
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

          return ListView.builder(
            itemCount: b.length,
            itemBuilder: (context, index) {
              final r = b.getAt(index);
              if (r == null) return const SizedBox.shrink();

              return ListTile(
                title: Text(r.name),
                subtitle: Text('${r.region} · ${r.district}'),
              );
            },
          );
        },
      ),
    );
  }
}
