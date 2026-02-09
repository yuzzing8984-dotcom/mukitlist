import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'restaurant_detail_page.dart';

class MapPage extends StatefulWidget {
  final dynamic selectedKeyFromList; // 리스트에서 탭한 Hive key
  final VoidCallback onConsumedSelectedKey;

  const MapPage({
    super.key,
    required this.selectedKeyFromList,
    required this.onConsumedSelectedKey,
  });

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  NaverMapController? _controller;
  StreamSubscription<BoxEvent>? _sub;

  final Map<dynamic, NMarker> _markers = {};
  Restaurant? _selectedRestaurant;

  dynamic _selectedKey; // ✅ Hive key
  double? _currentZoom;

  // ✅ 마커 아이콘(기본/선택) - 경로 통일
  final NOverlayImage _iconDefault =
  NOverlayImage.fromAssetImage('assets/markers/marker_food.png');
  final NOverlayImage _iconSelected =
  NOverlayImage.fromAssetImage('assets/markers/marker_food_selected.png');

  // ✅ 애니메이션(선택 핀만 살짝 팝)
  double _selectedScale = 1.0;
  bool _isAnimatingMarker = false;

  Box<Restaurant> get _box => Hive.box<Restaurant>('restaurants');
  String _selectedRegion = '전체';

  // ✅ 지역 좌표(필요한 것만 유지)
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

  // ✅ 전국(제주 포함) 초기 카메라
  static const NLatLng _koreaCenter = NLatLng(35.9, 127.7);
  static const double _koreaZoom = 5.8;

  // =========================
  // Lifecycle
  // =========================

  @override
  void initState() {
    super.initState();
    _sub = _box.watch().listen((_) async {
      await _syncMarkers();
      // 지역 자동 목록이 줄어드는 경우(삭제로 인해) 현재 선택 지역이 사라질 수 있음
      final regions = _getAvailableRegions();
      if (!regions.contains(_selectedRegion)) {
        if (!mounted) return;
        setState(() => _selectedRegion = '전체');
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final incomingKey = widget.selectedKeyFromList;
    if (incomingKey == null) return;

    // 같은거 또 들어오면 무시
    if (incomingKey == _selectedKey) {
      widget.onConsumedSelectedKey();
      return;
    }

    _selectByKeyFromList(incomingKey);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // =========================
  // Regions (saved only)
  // =========================

  List<String> _getAvailableRegions() {
    final regions = <String>{};
    for (final r in _box.values) {
      regions.add(r.region);
    }
    return ['전체', ...regions.toList()..sort()];
  }

  // =========================
  // Camera
  // =========================

  Future<void> _moveToRegion(String region) async {
    final c = _controller;
    if (c == null) return;

    final pos = _regionCamera[region];
    if (pos == null) return;

    await c.updateCamera(
      NCameraUpdate.withParams(target: pos.target, zoom: pos.zoom),
    );
  }

  Future<void> _moveToKorea() async {
    final c = _controller;
    if (c == null) return;

    await c.updateCamera(
      NCameraUpdate.withParams(target: _koreaCenter, zoom: _koreaZoom),
    );
  }

  /// ✅ 줌 유지 기본 + 너무 멀면 최소 14까지만 자동 확대
  Future<void> _focusRestaurant(Restaurant r) async {
    final c = _controller;
    if (c == null) return;
    if (r.lat == null || r.lng == null) return null;

    final z = _currentZoom ?? 12.0;
    final keepOrMin = z < 14.0 ? 14.0 : z;

    await c.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(r.lat!, r.lng!),
        zoom: keepOrMin,
      ),
    );
  }

  // =========================
  // Filtering / marker util
  // =========================

  bool _shouldShow(Restaurant r) {
    if (r.lat == null || r.lng == null) return false;
    if (_selectedRegion == '전체') return true;
    return r.region == _selectedRegion;
  }

  NOverlayImage _markerIcon(dynamic key) =>
      key == _selectedKey ? _iconSelected : _iconDefault;

  Size _markerSize(dynamic key) {
    final isSelected = key == _selectedKey;
    final base = isSelected ? 64.0 : 48.0;
    final scale = isSelected ? _selectedScale : 1.0;
    final s = base * scale;
    return Size(s, s);
  }

  int _markerZIndex(dynamic key) => key == _selectedKey ? 100 : 0;

  // =========================
  // List -> Map selection
  // =========================

  Future<void> _selectByKeyFromList(dynamic key) async {
    final r = _box.get(key);
    if (r == null) {
      widget.onConsumedSelectedKey();
      return;
    }

    // ✅ 지역 필터가 걸려있고 해당 지역이 아니면 UX상 전체로 풀어주기
    if (_selectedRegion != '전체' && r.region != _selectedRegion) {
      if (!mounted) return;
      setState(() => _selectedRegion = '전체');
      await _syncMarkers();
    }

    if (!mounted) return;
    final prevKey = _selectedKey;

    setState(() {
      _selectedKey = key;
      _selectedRestaurant = r;
      _selectedScale = 1.0;
    });

    // 아이콘/사이즈 반영
    await _refreshMarker(prevKey);
    await _refreshMarker(_selectedKey);

    await _playSelectPopAnimationOptimized();
    await _focusRestaurant(r);

    widget.onConsumedSelectedKey();
  }

  // =========================
  // Marker build / update
  // =========================

  NMarker _buildMarker({required dynamic key, required Restaurant r}) {
    debugPrint('MARKER ${r.name} lat=${r.lat} lng=${r.lng}'); // ✅ 정답

    final marker = NMarker(
      id: 'r_$key',
      position: NLatLng(r.lat!, r.lng!),
      icon: _markerIcon(key),
      size: _markerSize(key),
    );

    marker.setAnchor(const NPoint(0.5, 0.85));

    marker.setZIndex(_markerZIndex(key));

    marker.setOnTapListener((overlay) async {
      // 같은 핀 재탭 스킵
      if (_selectedKey == key) return;

      final prevKey = _selectedKey;

      if (!mounted) return;
      setState(() {
        _selectedKey = key;
        _selectedRestaurant = r;
        _selectedScale = 1.0;
      });

      // 바뀐 2개만 갱신
      await _refreshMarker(prevKey);
      await _refreshMarker(key);

      await _playSelectPopAnimationOptimized();
      await _focusRestaurant(r);
    });

    return marker;
  }

  Future<void> _refreshMarker(dynamic key) async {
    final c = _controller;
    if (c == null) return;
    if (key == null) return;

    // 기존 삭제
    final old = _markers[key];
    if (old != null) {
      await c.deleteOverlay(old.info);
      _markers.remove(key);
    }

    final r = _box.get(key);
    if (r == null) return;
    if (!_shouldShow(r)) return;

    final marker = _buildMarker(key: key, r: r);
    await c.addOverlay(marker);
    _markers[key] = marker;
  }

  Future<void> _syncMarkers() async {
    final c = _controller;
    if (c == null) return;

    for (final m in _markers.values) {
      await c.deleteOverlay(m.info);
    }
    _markers.clear();

    for (final key in _box.keys) {
      final r = _box.get(key);
      if (r == null) continue;
      if (!_shouldShow(r)) continue;

      final marker = _buildMarker(key: key, r: r);
      await c.addOverlay(marker);
      _markers[key] = marker;
    }
  }

  // =========================
  // Animation / clear selection
  // =========================

  Future<void> _playSelectPopAnimationOptimized() async {
    if (_isAnimatingMarker) return;
    _isAnimatingMarker = true;

    const frames = [1.00, 1.14, 1.06, 1.00];
    for (final s in frames) {
      if (!mounted) break;
      setState(() => _selectedScale = s);
      await _refreshMarker(_selectedKey);
      await Future.delayed(const Duration(milliseconds: 35));
    }

    _isAnimatingMarker = false;
  }

  Future<void> _clearSelectionOptimized() async {
    final prevKey = _selectedKey;
    if (_selectedRestaurant == null && prevKey == null) return;

    if (!mounted) return;
    setState(() {
      _selectedRestaurant = null;
      _selectedKey = null;
      _selectedScale = 1.0;
    });

    await _refreshMarker(prevKey);
  }

  // =========================
  // Detail / Delete
  // =========================

  Future<void> _openDetail(dynamic key, Restaurant r) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(
          hiveKey: key,
          restaurant: r,
        ),
      ),
    );

    if (deleted == true) {
      if (!mounted) return;
      setState(() {
        _selectedRestaurant = null;
        _selectedKey = null;
        _selectedScale = 1.0;
      });
      await _syncMarkers();
    }
  }


  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final regions = _getAvailableRegions();

    return Stack(
      children: [
        // ✅ NaverMap은 "딱 1개"만!
        NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: _koreaCenter,
              zoom: _koreaZoom,
            ),
          ),
          onMapReady: (controller) async {
            _controller = controller;
            _currentZoom = _koreaZoom;
            await _syncMarkers();
          },
          onCameraChange: (reason, animated) async {
            final c = _controller;
            if (c == null) return;
            final pos = await c.getCameraPosition();
            _currentZoom = pos.zoom;
          },
          onMapTapped: (point, latLng) {
            _clearSelectionOptimized();
          },
        ),

        // ✅ 상단: 지역 드롭다운(저장된 지역만)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: regions.contains(_selectedRegion)
                        ? _selectedRegion
                        : '전체',
                    isExpanded: true,
                    items: regions
                        .toSet()
                        .toList()
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 10),
                          child: Text(e),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;

                      if (!mounted) return;
                      setState(() {
                        _selectedRegion = v;
                        _selectedRestaurant = null;
                        _selectedKey = null;
                        _selectedScale = 1.0;
                      });

                      if (v == '전체') {
                        await _moveToKorea();
                      } else {
                        // 저장된 지역만 보여줘도, 카메라 포지션 없을 수 있음(예: 지역명 다르게 저장될 때)
                        if (_regionCamera.containsKey(v)) {
                          await _moveToRegion(v);
                        }
                      }

                      await _syncMarkers();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // ✅ 바텀시트
        if (_selectedRestaurant != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _RestaurantBottomSheet(
                restaurant: _selectedRestaurant!,
                onClose: _clearSelectionOptimized,
                onDetail: () => _openDetail(_selectedKey, _selectedRestaurant!),
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
