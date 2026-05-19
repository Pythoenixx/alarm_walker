import 'dart:async';
import 'dart:convert';

import 'package:alarm_walker/models/weather_model.dart';
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

  Future<WeatherModel> getCurrentWeather() async {
    final position = await _determinePosition();

    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': position.latitude.toStringAsFixed(4),
        'longitude': position.longitude.toStringAsFixed(4),
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
      return WeatherModel.fromOpenMeteo(decoded);
    } on FormatException catch (error) {
      throw WeatherException(error.message);
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const WeatherException(
        'Location service is turned off. Turn on location to show weather.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const WeatherException(
        'Location permission is needed to show weather.',
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
