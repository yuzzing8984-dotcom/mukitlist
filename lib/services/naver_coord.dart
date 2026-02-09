import 'package:proj4dart/proj4dart.dart';

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class NaverCoord {
  // Naver Local Search: mapx/mapy (TM128)
  // 많이 쓰는 TM128(Bessel) 파라미터
  static final _tm128 = Projection.add('TM128',
      '+proj=tmerc +lat_0=38 +lon_0=128 +k=1 +x_0=400000 +y_0=600000 '
          '+ellps=bessel +units=m +no_defs');

  static final _wgs84 = Projection.WGS84;

  /// mapx/mapy -> WGS84 lat/lng
  static LatLng toLatLng(dynamic mapx, dynamic mapy) {
    final x = _toDouble(mapx);
    final y = _toDouble(mapy);

    final p = Point(x: x, y: y);
    final converted = _tm128.transform(_wgs84, p);

    // proj4 결과는 x=lng, y=lat
    return LatLng(converted.y, converted.x);
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }
}
