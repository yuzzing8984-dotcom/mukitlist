import 'package:flutter/material.dart';
import '../models/restaurant.dart';

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

  // ✅ 추가
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _memoCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapUrlCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.region} 맛집 추가'),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '맛집 이름',
                  hintText: '예: 을밀대',
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '맛집 이름을 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(
                  labelText: '동네/구',
                  hintText: '예: 마포구',
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? '동네/구를 입력해줘' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memoCtrl,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '예: 수요미식회 보고 저장',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ✅ 좌표/링크 입력(선택)
              TextFormField(
                controller: _latCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: '위도(lat) (선택)',
                  hintText: '예: 37.5563',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: '경도(lng) (선택)',
                  hintText: '예: 126.9237',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapUrlCtrl,
                decoration: const InputDecoration(
                  labelText: '지도 링크(mapUrl) (선택)',
                  hintText: '네이버/카카오/구글 지도 URL',
                ),
              ),

              const SizedBox(height: 24),
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
