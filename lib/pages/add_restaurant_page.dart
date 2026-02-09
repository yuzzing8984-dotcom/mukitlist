import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/restaurant.dart';
import '../services/naver_local_search.dart';
import '../services/naver_coord.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();

  double? _pickedLat;
  double? _pickedLng;

  // ✅ 지역(페이지에서 선택) - 기본값 "미지정"
  static const List<String> _regions = [
    '미지정',
    '서울', '부산', '대구', '인천', '광주', '대전', '울산',
    '제주', '강원', '경기', '충북', '충남', '전북', '전남', '경북', '경남',
  ];
  String _selectedRegion = '미지정';

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController(); // ✅ 주소
  final _memoCtrl = TextEditingController();

  // ✅ UI에 안 보여도 좌표 저장용으로 유지
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();

  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String? _searchError;
  List<NaverLocalItem> _results = [];

  late final NaverLocalSearchService _naver;

  @override
  void initState() {
    super.initState();
    _naver = NaverLocalSearchService(
      clientId: dotenv.env['NAVER_CLIENT_ID']!,
      clientSecret: dotenv.env['NAVER_CLIENT_SECRET']!,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _memoCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isValidLatLng(double lat, double lng) {
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    if (lat == 0 || lng == 0) return false; // ✅ 0,0은 화면 밖/잘못된 값 방지
    return true;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // ❌ 이 두 줄은 삭제
    // final lat = double.tryParse(_latCtrl.text.trim());
    // final lng = double.tryParse(_lngCtrl.text.trim());

    // ✅ 이걸로 교체
    final lat = _pickedLat;
    final lng = _pickedLng;

    // ✅ 좌표 없거나 잘못된 값이면 저장 막기
    if (lat == null || lng == null || !_isValidLatLng(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('검색 결과를 선택해야 지도에 핀이 표시돼요'),
        ),
      );
      return;
    }

    final mapUrl = _mapUrlCtrl.text.trim();

    final restaurant = Restaurant(
      region: _selectedRegion,
      district: _districtCtrl.text.trim(), // ✅ 주소 전체
      name: _nameCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
      lat: lat,
      lng: lng,
      mapUrl: mapUrl.isEmpty ? null : mapUrl,
    );

    Navigator.pop(context, restaurant);
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

    // ✅ 여기 중요:
    // naver_local_search.dart에서 현재 item.lat/item.lng는 mapy/mapx(TM128) 파싱값임.
    // 파싱 실패하면 0이 들어올 수 있으니 여기서 한번 더 방어.
    if (item.lat == 0 || item.lng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좌표를 가져오지 못했어요. 다른 결과를 선택해줘!')),
      );
      return;
    }

    final converted = NaverCoord.toLatLng(item.lng, item.lat);
    _latCtrl.text = converted.lat.toStringAsFixed(6);
    _lngCtrl.text = converted.lng.toStringAsFixed(6);

    setState(() {
      _pickedLat = converted.lat;
      _pickedLng = converted.lng;
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
        title: const Text('맛집 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ 지역 선택
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

              // ✅ 검색
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

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ✅ 기본 입력
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '맛집 이름'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? '맛집 이름을 입력해줘'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(labelText: '주소'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? '주소를 입력해줘'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '메모'),
                maxLines: 3,
              ),

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
