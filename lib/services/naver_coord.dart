import 'package:proj4dart/proj4dart.dart';

class NaverCoord {
  static final Projection _tm128 = Projection.add(
    'TM128',
    '+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 '
        '+x_0=600000 +y_0=400000 +ellps=bessel +units=m +no_defs',
  );

  static final Projection _wgs84 = Projection.WGS84;

  static ({double lat, double lng}) toLatLng(double mapx, double mapy) {
    // 이미 위경도처럼 보이면 그대로
    final looksLng = mapx >= 120 && mapx <= 135;
    final looksLat = mapy >= 30 && mapy <= 40;
    if (looksLng && looksLat) {
      return (lat: mapy, lng: mapx);
    }

    // 1e7 스케일
    if (mapx.abs() > 1e8 && mapy.abs() > 1e8) {
      return (lat: mapy / 1e7, lng: mapx / 1e7);
    }

    final p = Point(x: mapx, y: mapy);
    final out = _wgs84.transform(_tm128, p);
    return (lat: out.y, lng: out.x);
  }
}
