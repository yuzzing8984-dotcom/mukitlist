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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final restaurant = Restaurant(
      region: widget.region,
      district: _districtCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      memo: _memoCtrl.text.trim(),
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
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
              const Spacer(),
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
