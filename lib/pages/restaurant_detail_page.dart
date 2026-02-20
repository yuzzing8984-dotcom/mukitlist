import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/restaurant.dart';
import 'add_restaurant_page.dart';

class RestaurantDetailPage extends StatefulWidget {
  final dynamic hiveKey;
  final Restaurant restaurant;

  const RestaurantDetailPage({
    super.key,
    required this.hiveKey,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late Restaurant _restaurant;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
  }

  Future<void> _onEditPressed() async {
    final updated = await Navigator.push<Restaurant>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRestaurantPage(initial: _restaurant),
      ),
    );

    if (updated == null) return;

    final box = Hive.box<Restaurant>('restaurants');
    await box.put(widget.hiveKey, updated);

    if (!mounted) return;
    setState(() => _restaurant = updated);
  }

  Future<void> _onDeletePressed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까?'),
        content: const Text('이 맛집을 목록에서 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final box = Hive.box<Restaurant>('restaurants');
      await box.delete(widget.hiveKey);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapQuery = _restaurant.name.trim(); // 🔥 지도는 name만
    final searchQuery =
        '${_restaurant.name} ${_restaurant.region}'.trim(); // 🔥 검색은 지역까지만

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant.name),
        actions: [
          IconButton(
            tooltip: '수정',
            icon: const Icon(Icons.edit),
            onPressed: _onEditPressed,
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: _onDeletePressed,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: '지역', value: _restaurant.region),
            const SizedBox(height: 8),
            _InfoRow(label: '동네', value: _restaurant.district),
            const SizedBox(height: 16),

            const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _restaurant.memo.trim().isEmpty
                    ? '메모 없음'
                    : _restaurant.memo,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openNaverMapSearch(mapQuery),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('네이버지도'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openNaverWebSearch(searchQuery),
                    icon: const Icon(Icons.search),
                    label: const Text('네이버검색'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ==========================
// 🔥 네이버 지도 열기
// ==========================

Future<void> openNaverMapSearch(String query) async {
  final encoded = Uri.encodeComponent(query);

  final appUri = Uri.parse(
    'nmap://search?query=$encoded&appname=com.mukitlist.app',
  );

  final webUri =
      Uri.parse('https://m.map.naver.com/search2/search.naver?query=$encoded');

  if (await canLaunchUrl(appUri)) {
    await launchUrl(appUri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

// ==========================
// 🔥 네이버 검색 열기
// ==========================

Future<void> openNaverWebSearch(String query) async {
  final encoded = Uri.encodeComponent(query);
  final uri =
      Uri.parse('https://m.search.naver.com/search.naver?query=$encoded');

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}