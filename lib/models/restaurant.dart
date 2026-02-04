import 'package:hive/hive.dart';

part 'restaurant.g.dart';

@HiveType(typeId: 0)
class Restaurant extends HiveObject {
  @HiveField(0)
  String region;

  @HiveField(1)
  String district;

  @HiveField(2)
  String name;

  @HiveField(3)
  String memo;

  // ✅ 추가: 좌표(핀용)
  @HiveField(4)
  double? lat;

  @HiveField(5)
  double? lng;

  // ✅ 추가: 지도 링크(네이버/카카오/구글)
  @HiveField(6)
  String? mapUrl;

  Restaurant({
    required this.region,
    required this.district,
    required this.name,
    required this.memo,
    this.lat,
    this.lng,
    this.mapUrl,
  });
}
