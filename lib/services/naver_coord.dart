import 'package:proj4dart/proj4dart.dart';

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class NaverCoord {
  // TM128 (GRS80) - fallback 용
  static final Projection _tm128 = Projection.add(
    'TM128_GRS80',
    '+proj=tmerc +lat_0=38 +lon_0=128 +k=1 '
        '+x_0=400000 +y_0=600000 +ellps=GRS80 +units=m +no_defs',
  );
  static final Projection _wgs84 = Projection.WGS84;

  /// 네이버 mapx/mapy -> WGS84 lat/lng
  static LatLng toLatLng(dynamic mapx, dynamic mapy) {
    final x = _toDouble(mapx);
    final y = _toDouble(mapy);

    // ✅ 1) WGS84 * 1e7 형태 (지금 네 사진이 이 케이스)
    // 예: lng=126.9839047 => mapx=1269839047
    if (x.abs() > 1e6 && y.abs() > 1e6) {
      final lat = y / 1e7;
      final lng = x / 1e7;
      return LatLng(lat, lng);
    }

    // ✅ 2) TM128 형태 (대략 수십만~백만 단위)
    if (x.abs() < 2e6 && y.abs() < 2e6) {
      final p = Point(x: x, y: y);
      final converted = _tm128.transform(_wgs84, p);
      return LatLng(converted.y, converted.x); // y=lat, x=lng
    }

    throw Exception('지원하지 않는 좌표 형식: mapx=$x mapy=$y');
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }
}
