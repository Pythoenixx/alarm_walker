class WeatherModel {
  final double temperature;
  final int weatherCode;
  final String condition;
  final String message;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;
  final bool isCached;
  final bool isManualLocation;

  const WeatherModel({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.message,
    this.locationName = 'Current location',
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.isCached = false,
    this.isManualLocation = false,
  });

  factory WeatherModel.fromOpenMeteo(
    Map<String, dynamic> json, {
    String locationName = 'Current location',
    double? latitude,
    double? longitude,
    bool isManualLocation = false,
    bool isCached = false,
    DateTime? updatedAt,
  }) {
    final current = json['current'];

    if (current is! Map<String, dynamic>) {
      throw const FormatException('Weather response is missing current data.');
    }

    final temperatureValue = current['temperature_2m'];
    final weatherCodeValue = current['weather_code'];

    if (temperatureValue is! num || weatherCodeValue is! num) {
      throw const FormatException('Weather response has invalid current data.');
    }

    final code = weatherCodeValue.toInt();
    final condition = conditionFromCode(code);

    return WeatherModel(
      temperature: temperatureValue.toDouble(),
      weatherCode: code,
      condition: condition,
      message: messageFromCode(code),
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      updatedAt: updatedAt ?? DateTime.now(),
      isCached: isCached,
      isManualLocation: isManualLocation,
    );
  }

  factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
    final temperatureValue = json['temperature'];
    final weatherCodeValue = json['weatherCode'];

    if (temperatureValue is! num || weatherCodeValue is! num) {
      throw const FormatException('Saved weather cache is invalid.');
    }

    final code = weatherCodeValue.toInt();
    final updatedAtText = json['updatedAt'];

    return WeatherModel(
      temperature: temperatureValue.toDouble(),
      weatherCode: code,
      condition:
          json['condition'] as String? ?? WeatherModel.conditionFromCode(code),
      message: json['message'] as String? ?? WeatherModel.messageFromCode(code),
      locationName: json['locationName'] as String? ?? 'Saved location',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt:
          updatedAtText is String ? DateTime.tryParse(updatedAtText) : null,
      isCached: true,
      isManualLocation: json['isManualLocation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'temperature': temperature,
    'weatherCode': weatherCode,
    'condition': condition,
    'message': message,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    'isManualLocation': isManualLocation,
  };

  WeatherModel copyWith({
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    bool? isCached,
    bool? isManualLocation,
  }) => WeatherModel(
    temperature: temperature,
    weatherCode: weatherCode,
    condition: condition,
    message: message,
    locationName: locationName ?? this.locationName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    updatedAt: updatedAt ?? this.updatedAt,
    isCached: isCached ?? this.isCached,
    isManualLocation: isManualLocation ?? this.isManualLocation,
  );

  String? get coordinateLabel {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return null;
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  static String conditionFromCode(int code) {
    return switch (code) {
      0 => 'Clear sky',
      1 || 2 || 3 => 'Partly cloudy',
      45 || 48 => 'Foggy',
      51 || 53 || 55 => 'Drizzle',
      56 || 57 => 'Freezing drizzle',
      61 || 63 || 65 => 'Rainy',
      66 || 67 => 'Freezing rain',
      71 || 73 || 75 => 'Snowy',
      77 => 'Snow grains',
      80 || 81 || 82 => 'Rain showers',
      85 || 86 => 'Snow showers',
      95 => 'Thunderstorm',
      96 || 99 => 'Thunderstorm with hail',
      _ => 'Unknown weather',
    };
  }

  static String messageFromCode(int code) {
    return switch (code) {
      0 => 'Clear morning. Great day to start early.',
      1 || 2 || 3 => 'Some clouds today. Plan your morning calmly.',
      45 || 48 => 'Foggy outside. Move carefully and give yourself extra time.',
      51 || 53 || 55 || 56 || 57 => 'Light rain is possible. Bring an umbrella just in case.',
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 =>
        'Rain expected. You may want to leave a little earlier.',
      71 || 73 || 75 || 77 || 85 || 86 =>
        'Cold and snowy conditions. Take extra care outside.',
      95 || 96 || 99 =>
        'Thunderstorm risk. Check the weather before going out.',
      _ => 'Weather information is available for your morning plan.',
    };
  }
}
