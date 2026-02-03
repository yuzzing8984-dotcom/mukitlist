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

  Restaurant({
    required this.region,
    required this.district,
    required this.name,
    required this.memo,
  });
}
