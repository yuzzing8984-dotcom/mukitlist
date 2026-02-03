import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/restaurant.dart';
import 'pages/region_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // RestaurantAdapter 는 build_runner로 생성된 restaurant.g.dart에 있음
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(RestaurantAdapter());
  }

  await Hive.openBox<Restaurant>('restaurants');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '먹킷리스트',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const RegionListPage(),
    );
  }
}
