import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final String message;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.message,
  });
}

class LocationService {
  static const double fallbackLatitude = 37.2636;
  static const double fallbackLongitude = 127.0286;

  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback('위치 서비스가 꺼져 있어 수원 기준 날씨를 사용했습니다.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallback(
          '위치 권한이 차단되어 수원 기준 날씨를 사용했습니다. 설정에서 위치 권한을 허용할 수 있습니다.',
        );
      }

      if (permission == LocationPermission.denied) {
        return _fallback('위치 권한이 허용되지 않아 수원 기준 날씨를 사용했습니다.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isFallback: false,
        message: '현재 위치를 확인해 해당 지역의 날씨를 요청했습니다.',
      );
    } on TimeoutException {
      return _fallback('현재 위치 확인 시간이 초과되어 수원 기준 날씨를 사용했습니다.');
    } catch (_) {
      return _fallback('현재 위치를 확인하지 못해 수원 기준 날씨를 사용했습니다.');
    }
  }

  LocationResult _fallback(String message) {
    return LocationResult(
      latitude: fallbackLatitude,
      longitude: fallbackLongitude,
      isFallback: true,
      message: message,
    );
  }
}
