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

class WeatherLocationResult {
  final String name;
  final double latitude;
  final double longitude;

  const WeatherLocationResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class WeatherService {
  const WeatherService();

  static const manualLocationNameKey = 'weatherManualLocationName';
  static const manualLatitudeKey = 'weatherManualLatitude';
  static const manualLongitudeKey = 'weatherManualLongitude';
  static const _weatherCacheKey = 'weatherLastSuccessfulResponse';

  Future<WeatherLocationResult> resolveLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      throw const WeatherException('Enter at least 2 characters for location.');
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': trimmed,
        'count': '1',
        'language': 'en',
        'format': 'json',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw WeatherException(
        'Unable to search weather location. Please try again. (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const WeatherException('Location search response is invalid.');
    }

    final results = decoded['results'];
    if (results is! List || results.isEmpty) {
      throw const WeatherException('No matching location found.');
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      throw const WeatherException('Location search response is invalid.');
    }

    final latitude = first['latitude'];
    final longitude = first['longitude'];
    final name = first['name'];

    if (latitude is! num || longitude is! num || name is! String) {
      throw const WeatherException('Location search result is incomplete.');
    }

    final parts = <String>[
      name,
      if (first['admin1'] is String) first['admin1'] as String,
      if (first['country'] is String) first['country'] as String,
    ];

    return WeatherLocationResult(
      name: parts.toSet().join(', '),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

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
    final prefs = SharedPreferencesWithCache.instance;
    final manualName = prefs.get<String>(manualLocationNameKey);
    final manualLatitude = prefs.get<double>(manualLatitudeKey);
    final manualLongitude = prefs.get<double>(manualLongitudeKey);

    if (manualName != null &&
        manualName.trim().isNotEmpty &&
        manualLatitude != null &&
        manualLongitude != null) {
      return _ResolvedWeatherLocation(
        name: manualName,
        latitude: manualLatitude,
        longitude: manualLongitude,
        isManual: true,
      );
    }

    final position = await _determinePosition();
    return _ResolvedWeatherLocation(
      name: 'Current location',
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
        'Location service is turned off. Set a manual weather location or turn on location.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const WeatherException(
        'Location permission is needed, or set a manual weather location in Settings.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const WeatherException(
        'Location permission is permanently denied. Set a manual weather location in Settings.',
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
