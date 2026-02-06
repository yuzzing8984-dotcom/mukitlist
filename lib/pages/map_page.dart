import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NaverMapController? _controller;

  final NMarker _testMarker = NMarker(
    id: 'test_marker',
    position: const NLatLng(37.5665, 126.9780),
  );

  bool _markerAdded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(37.5665, 126.9780),
              zoom: 14,
            ),
          ),
          onMapReady: (controller) async {
            _controller = controller;

            // hot reload / rebuild 시 중복 추가 방지
            if (!_markerAdded) {
              _markerAdded = true;
              await _controller!.addOverlay(_testMarker);

              _testMarker.setOnTapListener((overlay) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('테스트 마커 클릭됨!')),
                );
              });
            }
          },
        ),
      ),
    );
  }
}
