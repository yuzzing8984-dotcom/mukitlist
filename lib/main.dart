import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'models/restaurant.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(RestaurantAdapter());
  }

  await Hive.openBox<Restaurant>('restaurants');

  // ✅ 네이버 지도 SDK 초기화 (AndroidManifest.xml의 CLIENT_ID 사용)
  await NaverMapSdk.instance.initialize(
    onAuthFailed: (ex) {
      debugPrint("NaverMap auth failed: $ex");
    },
  );

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
      home: const HomePage(),
    );
  }
}
