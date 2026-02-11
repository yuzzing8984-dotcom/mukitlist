import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/restaurant.dart';
import '../services/naver_local_search.dart';
import '../services/naver_coord.dart';

class AddRestaurantPage extends StatefulWidget {
  final Restaurant? initial;      // ✅ 수정모드용
  final dynamic hiveKey;          // ✅ 수정 시 put에 쓸 키(선택)

  const AddRestaurantPage({
    super.key,
    this.initial,
    this.hiveKey,
  });

  bool get isEdit => initial != null;

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}


class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();

  static const List<String> _regions = [
    '미지정',
    '서울', '부산', '대구', '인천', '광주', '대전', '울산',
    '제주', '강원', '경기', '충북', '충남', '전북', '전남', '경북', '경남',
  ];
  String _selectedRegion = '미지정';

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController(); // 주소
  final _memoCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController(); // 저장용

  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String? _searchError;
  List<NaverLocalItem> _results = [];

  // ✅ 저장에 쓰는 최종 좌표(WGS84)
  double? _selectedLat;
  double? _selectedLng;

  // ✅ “검색 결과를 탭해서 선택됨” 여부
  bool _pickedFromSearch = false;

  late final NaverLocalSearchService _naver;

  void _invalidatePick() {
    if (!_pickedFromSearch) return;
    setState(() {
      _pickedFromSearch = false;
      _selectedLat = null;
      _selectedLng = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _naver = NaverLocalSearchService(
      clientId: dotenv.env['NAVER_CLIENT_ID']!,
      clientSecret: dotenv.env['NAVER_CLIENT_SECRET']!,
    );

    // ✅ 수정모드면 기존값 세팅
    final init = widget.initial;
    if (init != null) {
      _selectedRegion = init.region;
      _nameCtrl.text = init.name;
      _districtCtrl.text = init.district;
      _memoCtrl.text = init.memo;
      _mapUrlCtrl.text = init.mapUrl ?? '';

      _selectedLat = init.lat;
      _selectedLng = init.lng;

      // 수정은 이미 좌표가 있으니까 저장 허용
      _pickedFromSearch = true;
    }
      // ✅ 추가모드에서만: 이름/주소 직접 수정하면 '검색선택' 무효 처리
     if (widget.initial == null) {
       _nameCtrl.addListener(_invalidatePick);
       _districtCtrl.addListener(_invalidatePick);
    }
  }


  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _memoCtrl.dispose();
    _mapUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeKoreaWgs84(double lat, double lng) {
    return (lat >= 30 && lat <= 45) && (lng >= 120 && lng <= 135);
  }

  bool _isValidLatLng(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return _looksLikeKoreaWgs84(lat, lng);
  }

  bool get _canSave {
    final nameOk = _nameCtrl.text.trim().isNotEmpty;
    final addrOk = _districtCtrl.text.trim().isNotEmpty;

    final lat = _selectedLat;
    final lng = _selectedLng;
    final coordOk = lat != null && lng != null && _isValidLatLng(lat, lng);

    return nameOk && addrOk && coordOk && _pickedFromSearch;
  }

void _save() {
  if (!_formKey.currentState!.validate()) return;

  // ✅ 추가모드에서만 '검색 선택 강제'
  if (!widget.isEdit && !_canSave) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('검색 결과를 선택해야 지도에 핀이 표시돼요')),
    );
    return;
  }

  // 수정모드면 좌표는 기존값 허용
  if (_selectedLat == null || _selectedLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('좌표가 없습니다. 다시 검색해서 선택해줘')),
    );
    return;
  }

  final restaurant = Restaurant(
    region: _selectedRegion,
    district: _districtCtrl.text.trim(),
    name: _nameCtrl.text.trim(),
    memo: _memoCtrl.text.trim(),
    lat: _selectedLat!,
    lng: _selectedLng!,
    mapUrl: _mapUrlCtrl.text.trim().isEmpty ? null : _mapUrlCtrl.text.trim(),
  );

  Navigator.pop(context, restaurant); // ✅ 추가/수정 모두 Restaurant 반환
}


  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
      _results = [];
    });

    try {
      final items = await _naver.search(q, display: 10);
      if (!mounted) return;

      setState(() => _results = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _applySearchResult(NaverLocalItem item) {
    final name = item.cleanTitle;
    final addr = item.roadAddress.isNotEmpty ? item.roadAddress : item.address;

    _nameCtrl.text = name;
    _districtCtrl.text = addr;

    if (item.link.isNotEmpty) {
      _mapUrlCtrl.text = item.link;
    }

    final mapx = item.mapx;
    final mapy = item.mapy;

    double lat;
    double lng;

    // ✅ 1) WGS84 * 1e7 케이스 (지금 네 사진이 이거)
    // mapx=1269839047 -> lng=126.9839047
    // mapy=3757727663 -> lat=37.57727663
    if (mapx.abs() > 1e6 && mapy.abs() > 1e6) {
      lat = mapy / 1e7;
      lng = mapx / 1e7;
    }
    // ✅ 2) TM128 케이스(수십만~백만대) -> proj4 변환
    else {
      final converted = NaverCoord.toLatLng(mapx, mapy);
      lat = converted.lat;
      lng = converted.lng;
    }

    // ✅ 디버그 로그(콘솔 확인용)
    debugPrint('DEBUG mapx=$mapx mapy=$mapy => lat=$lat lng=$lng');

    if (!_isValidLatLng(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '좌표 변환 실패: lat=$lat lng=$lng (mapx=$mapx mapy=$mapy)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _pickedFromSearch = true;

      _results = [];
      _searchError = null;
    });

    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
  }


  @override
  Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isEdit ? '맛집 수정' : '맛집 추가'),
            actions: [
              TextButton(
                onPressed: _save,
                child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                items: _regions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedRegion = v);
                },
                decoration: const InputDecoration(labelText: '지역'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: '맛집 검색 (네이버)',
                  hintText: '가게 이름을 검색해봐',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searching ? null : _search,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _searching ? null : _search(),
              ),

              const SizedBox(height: 8),
              if (_searching) const LinearProgressIndicator(),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(_searchError!, style: const TextStyle(color: Colors.red)),
              ],

              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final addr = item.roadAddress.isNotEmpty
                          ? item.roadAddress
                          : item.address;

                      return ListTile(
                        dense: true,
                        title: Text(item.cleanTitle),
                        subtitle: Text(
                          addr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _applySearchResult(item),
                      );
                    },
                  ),
                ),
              ],

                            const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(
                      _pickedFromSearch ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: _pickedFromSearch ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _pickedFromSearch
                          ? '지도 위치가 선택되었습니다'
                          : '검색 결과를 선택해야 저장할 수 있어요',
                      style: TextStyle(
                        fontSize: 12,
                        color: _pickedFromSearch ? Colors.black54 : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '맛집 이름'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '맛집 이름을 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(labelText: '주소'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '주소를 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '메모'),
                maxLines: 3,
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
