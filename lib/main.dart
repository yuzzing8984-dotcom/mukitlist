import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return const MaterialApp(
      home: Scaffold(
        body: NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(37.5665, 126.9780),
              zoom: 14,
            ),
          ),
        ),
      ),
    );
  }
}
