class WeatherModel {
  final double temperature;
  final int weatherCode;
  final String condition;
  final String message;

  const WeatherModel({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.message,
  });

  factory WeatherModel.fromOpenMeteo(Map<String, dynamic> json) {
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
    );
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
