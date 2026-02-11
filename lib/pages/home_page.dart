import 'package:flutter/material.dart';

import 'map_page.dart';
import 'region_list_page.dart';
import '../models/restaurant.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_restaurant_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  dynamic _selectedRestaurantKeyFromList;

  void _onSelectRestaurantKey(dynamic key) {
    setState(() {
      _selectedRestaurantKeyFromList = key;
      _index = 0; // ✅ 지도 탭으로 이동
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MapPage(
            selectedKeyFromList: _selectedRestaurantKeyFromList,
            onConsumedSelectedKey: () {
              // ✅ 같은 key로 계속 재선택되는 것 방지
              setState(() => _selectedRestaurantKeyFromList = null);
            },
          ),
          RegionListPage(
            onSelectRestaurantKey: _onSelectRestaurantKey,
          ),
        ],
      ),

      floatingActionButton: _index == 0
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRestaurantPage(),
            ),
          );

          if (result != null) {
            final box = Hive.box<Restaurant>('restaurants');
            await box.add(result);
          }
        },
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '리스트'),
        ],
      ),
    );
  }
}
