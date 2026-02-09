import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/restaurant.dart';
import '../services/naver_local_search.dart';
import '../services/naver_coord.dart';

class AddRestaurantPage extends StatefulWidget {
  final String region;
  const AddRestaurantPage({super.key, required this.region});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    final mapUrl = _mapUrlCtrl.text.trim();

    final restaurant = Restaurant(
      region: widget.region,
      district: _districtCtrl.text.trim(),
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

  String _pickDistrict(String address) {
    // 아주 간단한 “구/동” 추출 시도
    // 예: "서울특별시 마포구 월드컵로 26 ..." -> "마포구"
    final parts = address.split(' ');
    for (final p in parts) {
      if (p.endsWith('구') || p.endsWith('군') || p.endsWith('시')) return p;
    }
    // 못 찾으면 주소 그대로 넣지 말고 빈칸 유지(사용자가 입력)
    return '';
  }

  void _applySearchResult(NaverLocalItem item) {
    final name = item.cleanTitle;
    final addr = item.roadAddress.isNotEmpty ? item.roadAddress : item.address;

    _nameCtrl.text = name;

    _districtCtrl.text = addr;


    if (item.link.isNotEmpty) {
      _mapUrlCtrl.text = item.link;
    }

    final converted = NaverCoord.toLatLng(item.lng, item.lat);
    _latCtrl.text = converted.lat.toStringAsFixed(6);
    _lngCtrl.text = converted.lng.toStringAsFixed(6);

    setState(() {
      _results = [];
      _searchError = null;
    });
    _searchCtrl.clear(); // (원하면) 검색어도 지움
    FocusScope.of(context).unfocus(); // 키보드 닫기

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.region;

    return Scaffold(
      appBar: AppBar(
        title: const Text('맛집 추가'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
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
              // ✅ 검색
              TextFormField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: '맛집 검색 (네이버)',
                  hintText: '예: 을밀대 마포',
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
                      final addr = item.roadAddress.isNotEmpty ? item.roadAddress : item.address;

                      return ListTile(
                        dense: true,
                        title: Text(item.cleanTitle),
                        subtitle: Text(addr, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? '맛집 이름을 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(labelText: '동네/구'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '동네/구를 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memoCtrl,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

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
