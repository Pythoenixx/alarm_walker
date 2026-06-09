import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/weather_model.dart';
import 'package:alarm_walker/services/weather_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class WeatherCard extends StatefulWidget {
  final WeatherService service;

  const WeatherCard({
    super.key,
    this.service = const WeatherService(),
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late Future<WeatherModel> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = widget.service.getCurrentWeather();
  }

  Future<WeatherModel> _loadWeather({bool showRefreshFeedback = false}) async {
    try {
      final weather = await widget.service.getCurrentWeather();
      if (showRefreshFeedback && mounted && weather.isCached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Weather refresh needs location and internet. Showing last saved weather.'),
            ),
          ),
        );
      }
      return weather;
    } catch (error) {
      if (showRefreshFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyRefreshError(context, error),
            ),
          ),
        );
      }
      rethrow;
    }
  }

  String _friendlyRefreshError(BuildContext context, Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('location')) {
      return context.tr('Weather refresh needs location and internet. Please enable both, then try again.');
    }
    return context.tr('Weather refresh needs internet. Please check your connection, then try again.');
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = _loadWeather(showRefreshFeedback: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkGradient1, AppColors.darkGradient2]
              : [Colors.white.withValues(alpha: 0.75), AppColors.lightSurface],
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.shadowLight.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FutureBuilder<WeatherModel>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _WeatherLoading(isDark: isDark);
          }

          if (snapshot.hasError) {
            return _WeatherError(
              message: snapshot.error.toString(),
              onRefresh: _refreshWeather,
              isDark: isDark,
            );
          }

          final weather = snapshot.data;

          if (weather == null) {
            return _WeatherError(
              message: context.tr('Weather data is unavailable.'),
              onRefresh: _refreshWeather,
              isDark: isDark,
            );
          }

          return _WeatherContent(
            weather: weather,
            onRefresh: _refreshWeather,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _WeatherLoading extends StatelessWidget {
  final bool isDark;

  const _WeatherLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr('Loading weather...'),
            style: AppTextStyles.body(context).copyWith(
              color: isDark
                  ? AppColors.darkBackgroundText
                  : AppColors.lightBackgroundText,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherError extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;
  final bool isDark;

  const _WeatherError({
    required this.message,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(alpha: 0.14),
          ),
          child: const Icon(
            Icons.location_off_outlined,
            color: Colors.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Weather unavailable'),
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkBackgroundText
                      : AppColors.lightBackgroundText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(message),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.tr('Retry'),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback onRefresh;
  final bool isDark;

  const _WeatherContent({
    required this.weather,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: Icon(
            _iconForCode(weather.weatherCode),
            color: AppColors.primary,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: AppTextStyles.large(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.tr(weather.condition),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _locationTooltip(context, weather),
                    child: Icon(
                      weather.isManualLocation
                          ? Icons.place_outlined
                          : Icons.my_location_outlined,
                      size: 15,
                      color: AppColors.primary.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(weather.message),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withValues(alpha: 0.74),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.tr('Refresh weather'),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }

  String _locationTooltip(BuildContext context, WeatherModel weather) {
    final location = weather.locationName.trim();
    if (location.startsWith('GPS ')) {
      return context.tr('Weather source: {location}', {'location': location});
    }
    if (location == 'Last known location') {
      final coordinates = weather.coordinateLabel;
      if (coordinates != null) {
        return context.tr(
          'Weather source: last known location ({coordinates})',
          {'coordinates': coordinates},
        );
      }
      return context.tr('Weather source: {location}', {
        'location': context.tr(location),
      });
    }
    if (location.isNotEmpty && location != 'Current location') {
      return context.tr('Weather source: {location}', {
        'location': context.tr(location),
      });
    }
    return context.tr('Weather source: device location');
  }

  IconData _iconForCode(int code) {
    return switch (code) {
      0 => Icons.wb_sunny_outlined,
      1 || 2 || 3 => Icons.cloud_outlined,
      45 || 48 => Icons.cloud_outlined,
      51 || 53 || 55 || 56 || 57 => Icons.grain,
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.opacity,
      71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
      95 || 96 || 99 => Icons.flash_on,
      _ => Icons.cloud_outlined,
    };
  }
}
