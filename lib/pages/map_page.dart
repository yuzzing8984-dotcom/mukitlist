import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NaverMapController? _controller;

  // 중복 추가 방지용
  final Set<String> _addedMarkerIds = {};

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Restaurant>('restaurants');

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Restaurant> b, _) {
          return SafeArea(
            child: NaverMap(
              options: const NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(37.5665, 126.9780),
                  zoom: 13,
                ),
              ),
              onMapReady: (controller) async {
                _controller = controller;
                await _syncMarkersFromHive(b);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _syncMarkersFromHive(Box<Restaurant> box) async {
    final controller = _controller;
    if (controller == null) return;

    // Hive에 저장된 맛집 중 lat/lng 있는 것만 핀 생성
    for (int i = 0; i < box.length; i++) {
      final r = box.getAt(i);
      if (r == null) continue;
      if (r.lat == null || r.lng == null) continue;

      // id는 안정적으로: hive index 기반
      final markerId = 'r_$i';

      if (_addedMarkerIds.contains(markerId)) continue;

      final marker = NMarker(
        id: markerId,
        position: NLatLng(r.lat!, r.lng!),
      );

      marker.setOnTapListener((overlay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${r.name} (${r.region} · ${r.district})')),
        );
      });

      await controller.addOverlay(marker);
      _addedMarkerIds.add(markerId);
    }
  }
}
