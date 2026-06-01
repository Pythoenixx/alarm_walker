import 'dart:async';
import 'dart:convert';

import 'package:alarm_walker/models/weather_model.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherException implements Exception {
  final String message;

  const WeatherException(this.message);

  @override
  String toString() => message;
}


class WeatherService {
  const WeatherService();

  static const manualLocationNameKey = 'weatherManualLocationName';
  static const manualLatitudeKey = 'weatherManualLatitude';
  static const manualLongitudeKey = 'weatherManualLongitude';
  static const _weatherCacheKey = 'weatherLastSuccessfulResponse';

  Future<WeatherModel> getCurrentWeather() async {
    try {
      final location = await _loadWeatherLocation();
      final weather = await _fetchCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: location.name,
        isManualLocation: location.isManual,
      );
      await _saveCachedWeather(weather);
      return weather;
    } catch (error) {
      final cached = _loadCachedWeather();
      if (cached != null) return cached;

      if (error is WeatherException) rethrow;
      throw WeatherException(error.toString());
    }
  }

  Future<_ResolvedWeatherLocation> _loadWeatherLocation() async {
    final position = await _determinePosition();
    final lat = position.latitude.toStringAsFixed(2);
    final lon = position.longitude.toStringAsFixed(2);
    return _ResolvedWeatherLocation(
      name: 'GPS $lat, $lon',
      latitude: position.latitude,
      longitude: position.longitude,
      isManual: false,
    );
  }

  Future<WeatherModel> _fetchCurrentWeather({
    required double latitude,
    required double longitude,
    required String locationName,
    required bool isManualLocation,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw WeatherException(
        'Unable to load weather. Please try again later. (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const WeatherException('Weather response format is invalid.');
    }

    try {
      return WeatherModel.fromOpenMeteo(
        decoded,
        locationName: locationName,
        isManualLocation: isManualLocation,
      );
    } on FormatException catch (error) {
      throw WeatherException(error.message);
    }
  }

  Future<void> _saveCachedWeather(WeatherModel weather) async {
    await SharedPreferencesWithCache.instance.setString(
      _weatherCacheKey,
      jsonEncode(weather.toCacheJson()),
    );
  }

  WeatherModel? _loadCachedWeather() {
    final cacheText = SharedPreferencesWithCache.instance.get<String>(
      _weatherCacheKey,
    );
    if (cacheText == null || cacheText.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(cacheText);
      if (decoded is! Map<String, dynamic>) return null;
      return WeatherModel.fromCacheJson(decoded).copyWith(isCached: true);
    } catch (_) {
      return null;
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const WeatherException(
        'Location service is turned off. Turn on location to refresh weather.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const WeatherException(
        'Location permission is needed to refresh weather.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const WeatherException(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }
}

class _ResolvedWeatherLocation {
  final String name;
  final double latitude;
  final double longitude;
  final bool isManual;

  const _ResolvedWeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isManual,
  });
}
