import 'package:flutter/material.dart';

import 'map_page.dart';
import 'region_list_page.dart';
import '../models/restaurant.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_restaurant_page.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart'; // SystemNavigator.pop()

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  dynamic _selectedRestaurantKeyFromList;

  // ✅ 종료 전면광고
  InterstitialAd? _exitAd;
  bool _isExitAdReady = false;
  bool _isShowingExitAd = false;

  // ✅ 전면 테스트 광고 ID (Android)
  static const String _testInterstitialId = 'ca-app-pub-5404045286509114/1975823695';

  @override
  void initState() {
    super.initState();
    _loadExitAd();
  }

  void _loadExitAd() {
    InterstitialAd.load(
      adUnitId: _testInterstitialId, // TODO: 출시 시 실제 전면광고 ID로 교체
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _exitAd = ad;
          _isExitAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _exitAd = null;
              _isExitAdReady = false;
              _isShowingExitAd = false;

              // ✅ 광고 닫히면 종료
              SystemNavigator.pop();

              // (선택) 다음을 위해 다시 로드
              _loadExitAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _exitAd = null;
              _isExitAdReady = false;
              _isShowingExitAd = false;

              // ✅ 실패하면 그냥 종료
              SystemNavigator.pop();

              // (선택) 다시 로드
              _loadExitAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _exitAd = null;
          _isExitAdReady = false;
        },
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('앱을 종료할까요?'),
          content: const Text('종료하면 앱이 닫힙니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('종료'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _onWillPop() async {
    // 이미 광고 띄우는 중이면 back 막기
    if (_isShowingExitAd) return false;

    // ✅ 1) 리스트 탭에서 뒤로 -> 지도 탭으로 이동
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }

    // ✅ 2) 지도 탭에서 뒤로 -> 종료 확인 팝업
    final ok = await _showExitDialog();
    if (!ok) return false;

    // ✅ 3) 확인 누르면 전면광고(있으면) -> 종료
    if (_isExitAdReady && _exitAd != null) {
      _isShowingExitAd = true;
      _exitAd!.show();
      return false;
    }

    // 광고 준비 안됐으면 바로 종료
    return true;
  }

  void _onSelectRestaurantKey(dynamic key) {
    setState(() {
      _selectedRestaurantKeyFromList = key;
      _index = 0; // ✅ 지도 탭으로 이동
    });
  }

  @override
  void dispose() {
    _exitAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            MapPage(
              selectedKeyFromList: _selectedRestaurantKeyFromList,
              onConsumedSelectedKey: () {
                setState(() => _selectedRestaurantKeyFromList = null);
              },
            ),
            RegionListPage(
              onSelectRestaurantKey: _onSelectRestaurantKey,
            ),
          ],
        ),

        floatingActionButton: _index == 0
            ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRestaurantPage(),
                    ),
                  );

                  if (result != null) {
                    final box = Hive.box<Restaurant>('restaurants');
                    await box.add(result);
                  }
                },
              )
            : null,

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '리스트'),
          ],
        ),
      ),
    );
  }
}