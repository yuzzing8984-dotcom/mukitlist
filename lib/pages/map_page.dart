import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NaverMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지도')),
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780), // 서울시청 근처
                zoom: 12,
              ),
            ),
            onMapReady: (controller) async {
              _controller = controller;

              // ✅ 더미 마커 1개 (지도 뜨는지 확인용)
              final marker = NMarker(
                id: 'dummy',
                position: const NLatLng(37.5665, 126.9780),
              );
              await controller.addOverlay(marker);
            },
          ),

          // ✅ 안내 문구 (지도 위에 겹쳐서 보여주기)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '1단계: 지도는 무조건 보이게!\n(지금은 더미 마커 1개 찍어둠)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
