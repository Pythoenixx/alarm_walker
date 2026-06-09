import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/weather_model.dart';
import 'package:alarm_walker/services/weather_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class WeatherAlarmCard extends StatefulWidget {
  final WeatherService service;

  const WeatherAlarmCard({
    super.key,
    this.service = const WeatherService(),
  });

  @override
  State<WeatherAlarmCard> createState() => _WeatherAlarmCardState();
}

class _WeatherAlarmCardState extends State<WeatherAlarmCard> {
  late Future<WeatherModel> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = widget.service.getCurrentWeather();
  }

  void _retry() {
    setState(() {
      _weatherFuture = widget.service.getCurrentWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: FutureBuilder<WeatherModel>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _WeatherAlarmShell(
              isDark: isDark,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('Checking weather...'),
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _WeatherAlarmShell(
              isDark: isDark,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('Weather message unavailable'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _retry,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            );
          }

          final weather = snapshot.data!;

          return _WeatherAlarmShell(
            isDark: isDark,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconForCode(weather.weatherCode), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _weatherSummary(context, weather),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.isCached
                            ? context.tr(
                                '{message} · using saved weather',
                                {'message': context.tr(weather.message)},
                              )
                            : context.tr(weather.message),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  String _weatherSummary(BuildContext context, WeatherModel weather) {
    return context.tr(
      '{temperature}°C · {condition} · {location}',
      {
        'temperature': weather.temperature.round(),
        'condition': context.tr(weather.condition),
        'location': context.tr(weather.locationName),
      },
    );
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

class _WeatherAlarmShell extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _WeatherAlarmShell({
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkScaffold1.withOpacity(0.72)
            : Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.white,
        ),
      ),
      child: child,
    );
  }
}
