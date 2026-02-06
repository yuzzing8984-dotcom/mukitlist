import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'restaurant_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NaverMapController? _controller;
  StreamSubscription<BoxEvent>? _sub;

  final Map<dynamic, NMarker> _markers = {};
  Restaurant? _selectedRestaurant;

  Box<Restaurant> get _box => Hive.box<Restaurant>('restaurants');

  String _selectedRegion = '전체';

  // ✅ 간단 지역 좌표 맵 (원하는 거 더 추가 가능)
  final Map<String, NCameraPosition> _regionCamera = {
    '서울': const NCameraPosition(target: NLatLng(37.5665, 126.9780), zoom: 11),
    '부산': const NCameraPosition(target: NLatLng(35.1796, 129.0756), zoom: 11),
    '대구': const NCameraPosition(target: NLatLng(35.8714, 128.6014), zoom: 11),
    '인천': const NCameraPosition(target: NLatLng(37.4563, 126.7052), zoom: 11),
    '광주': const NCameraPosition(target: NLatLng(35.1595, 126.8526), zoom: 11),
    '대전': const NCameraPosition(target: NLatLng(36.3504, 127.3845), zoom: 11),
    '울산': const NCameraPosition(target: NLatLng(35.5384, 129.3114), zoom: 11),
    '제주': const NCameraPosition(target: NLatLng(33.4996, 126.5312), zoom: 10),
    '강원': const NCameraPosition(target: NLatLng(37.8228, 128.1555), zoom: 9),
    '경기': const NCameraPosition(target: NLatLng(37.4138, 127.5183), zoom: 9),
    '충북': const NCameraPosition(target: NLatLng(36.6357, 127.4915), zoom: 9),
    '충남': const NCameraPosition(target: NLatLng(36.5184, 126.8000), zoom: 9),
    '전북': const NCameraPosition(target: NLatLng(35.7175, 127.1530), zoom: 9),
    '전남': const NCameraPosition(target: NLatLng(34.8161, 126.4629), zoom: 9),
    '경북': const NCameraPosition(target: NLatLng(36.4919, 128.8889), zoom: 9),
    '경남': const NCameraPosition(target: NLatLng(35.4606, 128.2132), zoom: 9),
  };

  // ✅ 한국 전체 초기 카메라
  static const NLatLng _koreaCenter = NLatLng(36.5, 127.8);
  static const double _koreaZoom = 6.5;

  @override
  void initState() {
    super.initState();
    // Hive 변경 시 마커 갱신
    _sub = _box.watch().listen((_) => _syncMarkers());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _moveToRegion(String region) async {
    final c = _controller;
    if (c == null) return;

    final pos = _regionCamera[region];
    if (pos == null) return;

    await c.updateCamera(
      NCameraUpdate.withParams(
        target: pos.target,
        zoom: pos.zoom,
      ),
    );
  }

  Future<void> _moveToKorea() async {
    final c = _controller;
    if (c == null) return;

    await c.updateCamera(
      NCameraUpdate.withParams(
        target: _koreaCenter,
        zoom: _koreaZoom,
      ),
    );
  }

  Future<void> _focusRestaurant(Restaurant r) async {
    final c = _controller;
    if (c == null) return;
    if (r.lat == null || r.lng == null) return;

    // 1) 핀으로 이동 + 확대
    await c.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(r.lat!, r.lng!),
        zoom: 14,
      ),
    );

    // 2) (선택) 시트가 아래에서 올라오니 핀을 살짝 위로
    // 숫자(-120 ~ -240) 정도로 취향 조절
      }

  Future<void> _syncMarkers() async {
    final c = _controller;
    if (c == null) return;

    // 1) 기존 마커 제거
    for (final m in _markers.values) {
      await c.deleteOverlay(m.info);
    }
    _markers.clear();

    // 2) Hive 데이터 → 마커 생성
    for (final key in _box.keys) {
      final r = _box.get(key);
      if (r == null) continue;
      if (r.lat == null || r.lng == null) continue;

      // ✅ 지역 필터(전체면 다 보여줌)
      if (_selectedRegion != '전체' && r.region != _selectedRegion) {
        continue;
      }

      final marker = NMarker(
        id: 'r_$key',
        position: NLatLng(r.lat!, r.lng!),
      );

      // ✅ 마커 탭: 카메라 이동/확대 + 시트 표시
      marker.setOnTapListener((overlay) async {
        await _focusRestaurant(r);
        if (!mounted) return;
        setState(() => _selectedRestaurant = r);
      });

      await c.addOverlay(marker);
      _markers[key] = marker;
    }
  }

  Future<void> _openDetail(Restaurant r) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(restaurant: r),
      ),
    );

    if (deleted != true) return;

    // ✅ 상세페이지에서 "삭제" 눌렀으면 Hive에서 삭제
    dynamic keyToDelete;
    for (final k in _box.keys) {
      final item = _box.get(k);
      if (item == null) continue;

      final same = item.name == r.name &&
          item.region == r.region &&
          item.district == r.district &&
          item.memo == r.memo &&
          item.lat == r.lat &&
          item.lng == r.lng;

      if (same) {
        keyToDelete = k;
        break;
      }
    }

    if (keyToDelete != null) {
      await _box.delete(keyToDelete);
    }

    if (mounted) {
      setState(() => _selectedRestaurant = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regions = <String>['전체', ..._regionCamera.keys];

    return Stack(
      children: [
        // 🗺 지도
        NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: _koreaCenter,
              zoom: _koreaZoom,
            ),
          ),
          onMapReady: (controller) async {
            _controller = controller;
            await _syncMarkers();
          },
          onMapTapped: (point, latLng) {
            // 지도 탭하면 시트 닫기
            if (_selectedRestaurant != null) {
              setState(() => _selectedRestaurant = null);
            }
          },
        ),

        // ✅ 상단: 지역 드롭다운(풀사이즈)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    items: regions
                        .toSet()
                        .toList()
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(e),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;

                      setState(() {
                        _selectedRegion = v;
                        _selectedRestaurant = null; // 필터 바뀌면 시트 닫기
                      });

                      if (v == '전체') {
                        await _moveToKorea();
                      } else {
                        await _moveToRegion(v);
                      }

                      await _syncMarkers();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // ✅ 바텀탭 가리게 + 위아래 드래그 되는 시트
        if (_selectedRestaurant != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _RestaurantBottomSheet(
                restaurant: _selectedRestaurant!,
                onClose: () => setState(() => _selectedRestaurant = null),
                onDetail: () => _openDetail(_selectedRestaurant!),
              ),
            ),
          ),
      ],
    );
  }
}

class _RestaurantBottomSheet extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _RestaurantBottomSheet({
    required this.restaurant,
    required this.onClose,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // ✅ 바텀탭 가려도 되고, 아래로도 내려가게
      minChildSize: 0.15,
      initialChildSize: 0.28,
      maxChildSize: 0.85,
      snap: false,
      builder: (context, scrollController) {
        return Material(
          elevation: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Colors.black26,
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${restaurant.region} · ${restaurant.district}'),

              if (restaurant.memo.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(restaurant.memo),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDetail,
                  child: const Text('상세보기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
