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
  static const _locationCacheKey = 'weatherLastSuccessfulLocation';

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
    try {
      final position = await _determinePosition();
      final lat = position.latitude.toStringAsFixed(2);
      final lon = position.longitude.toStringAsFixed(2);
      final location = _ResolvedWeatherLocation(
        name: 'GPS $lat, $lon',
        latitude: position.latitude,
        longitude: position.longitude,
        isManual: false,
      );
      await _saveCachedLocation(location);
      return location;
    } on WeatherException {
      final cachedLocation = _loadCachedLocation();
      if (cachedLocation != null) return cachedLocation;
      rethrow;
    }
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
        latitude: latitude,
        longitude: longitude,
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

  Future<void> _saveCachedLocation(_ResolvedWeatherLocation location) async {
    await SharedPreferencesWithCache.instance.setString(
      _locationCacheKey,
      jsonEncode({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'name': location.name,
        'isManual': location.isManual,
      }),
    );
  }

  _ResolvedWeatherLocation? _loadCachedLocation() {
    final cacheText = SharedPreferencesWithCache.instance.get<String>(
      _locationCacheKey,
    );
    if (cacheText == null || cacheText.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(cacheText);
      if (decoded is! Map<String, dynamic>) return null;

      final latitude = decoded['latitude'];
      final longitude = decoded['longitude'];
      if (latitude is! num || longitude is! num) return null;

      return _ResolvedWeatherLocation(
        // Do not claim this is the live GPS position. It is only the most
        // recent location that previously worked for weather refresh.
        name: 'Last known location',
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        isManual: decoded['isManual'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
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
