import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late NaverMapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780), // 서울시청
                zoom: 14,
              ),
              mapType: NMapType.basic,
              indoorEnable: false,
              locationButtonEnable: false,
            ),
            onMapReady: (controller) async {
              _controller = controller;

              // 테스트 마커
              final marker = NMarker(
                id: 'test',
                position: const NLatLng(37.5665, 126.9780),
              );
              await _controller.addOverlay(marker);
            },
          ),
        ),
      ),
    );
  }
}
