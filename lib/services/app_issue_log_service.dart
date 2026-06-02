import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppIssueLogService {
  AppIssueLogService._();

  static const String collectionName = 'app_issue_logs';
  static String _appArea = 'user_app';
  static final Map<String, DateTime> _recentLogKeys = {};
  static Future<Map<String, String>>? _buildInfoFuture;

  static void initialize({required String appArea}) {
    _appArea = appArea;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(recordFlutterError(details));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        recordError(
          error,
          stackTrace,
          source: '${_appArea}_platform_dispatcher',
        ),
      );
      return false;
    };
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final stack = details.stack ?? StackTrace.current;
    final message = details.exceptionAsString();
    final contextText = details.context?.toDescription();
    final diagnosticsText = _trim(details.toString(), 10000);
    final sourceLocation = _extractSourceLocation(diagnosticsText, stack);
    final relevantWidget = _extractRelevantWidget(diagnosticsText);

    return recordError(
      exception,
      stack,
      source: 'flutter_framework',
      screen: contextText,
      message: message,
      fatal: false,
      details: {
        'flutterContext': contextText ?? '',
        'flutterLibrary': details.library ?? '',
        'exceptionType': exception.runtimeType.toString(),
        'possibleSourceLocation': sourceLocation,
        'relevantWidget': relevantWidget,
        'flutterDiagnostics': diagnosticsText,
      },
    );
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String source,
    String? screen,
    String? message,
    bool fatal = true,
    Map<String, Object?> details = const {},
  }) async {
    final cleanMessage = _trim(message ?? error.toString(), 700);
    final duplicateKey = '$source|$_appArea|$cleanMessage';

    if (_isDuplicate(duplicateKey)) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final buildInfo = await buildInfoFields();
      await FirebaseFirestore.instance.collection(collectionName).add({
        'message': cleanMessage,
        'error': _trim(error.toString(), 1200),
        'stackTrace': _trim(stackTrace.toString(), 8000),
        'source': source,
        'screen': screen ?? '',
        'severity': fatal ? 'crash' : 'problem',
        'status': 'open',
        'appArea': _appArea,
        'platform': _platformLabel,
        'isWeb': kIsWeb,
        'isReleaseMode': kReleaseMode,
        ...buildInfo,
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'details': _safeDetails({
          ..._runtimeDetails(screen),
          ...buildInfo,
          ...details,
        }),
        'createdAt': FieldValue.serverTimestamp(),
        'clientCreatedAt': DateTime.now().toIso8601String(),
      });
    } catch (loggingError) {
      debugPrint('Failed to upload app issue log: $loggingError');
    }
  }

  static Future<void> recordManualIssue({
    required String message,
    required String source,
    String? screen,
    Map<String, Object?> details = const {},
  }) {
    return recordError(
      StateError(message),
      StackTrace.current,
      source: source,
      screen: screen,
      message: message,
      fatal: false,
      details: details,
    );
  }


  static Future<Map<String, String>> buildInfoFields() {
    _buildInfoFuture ??= _loadBuildInfoFields();
    return _buildInfoFuture!;
  }

  static Future<Map<String, String>> _loadBuildInfoFields() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final buildNumber = info.buildNumber.trim();
      final buildLabel = buildNumber.isEmpty ? version : '$version+$buildNumber';

      return {
        'appVersion': version,
        'buildNumber': buildNumber,
        'buildLabel': buildLabel,
      };
    } catch (_) {
      return {
        'appVersion': 'unknown',
        'buildNumber': 'unknown',
        'buildLabel': 'unknown',
      };
    }
  }

  static bool _isDuplicate(String key) {
    final now = DateTime.now();
    final lastTime = _recentLogKeys[key];
    _recentLogKeys[key] = now;

    _recentLogKeys.removeWhere(
      (_, value) => now.difference(value) > const Duration(minutes: 2),
    );

    if (lastTime == null) return false;
    return now.difference(lastTime) < const Duration(seconds: 20);
  }

  static String get _platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static Map<String, Object?> _runtimeDetails(String? screen) {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return {
        'screenContext': screen ?? '',
      };
    }

    final view = views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    final logicalWidth = physicalSize.width / devicePixelRatio;
    final logicalHeight = physicalSize.height / devicePixelRatio;

    return {
      'screenContext': screen ?? '',
      'logicalSize': '${logicalWidth.toStringAsFixed(0)} x ${logicalHeight.toStringAsFixed(0)}',
      'physicalSize': '${physicalSize.width.toStringAsFixed(0)} x ${physicalSize.height.toStringAsFixed(0)}',
      'devicePixelRatio': devicePixelRatio.toStringAsFixed(2),
    };
  }

  static Map<String, Object?> _safeDetails(Map<String, Object?> details) {
    return details.map((key, value) {
      if (value == null || value is String || value is num || value is bool) {
        return MapEntry(key, value);
      }
      return MapEntry(key, value.toString());
    });
  }


  static String _extractSourceLocation(
    String diagnosticsText,
    StackTrace stackTrace,
  ) {
    final combined = '$diagnosticsText\n$stackTrace';
    final projectMatch = RegExp(
      r'(lib/[\w_./-]+\.dart:\d+:\d+)',
    ).firstMatch(combined);
    if (projectMatch != null) return projectMatch.group(1) ?? '';

    final fileUriMatch = RegExp(
      r'file:///[^\s)]+/lib/([\w_./-]+\.dart:\d+:\d+)',
    ).firstMatch(combined);
    if (fileUriMatch != null) return 'lib/${fileUriMatch.group(1)}';

    return '';
  }

  static String _extractRelevantWidget(String diagnosticsText) {
    final marker = 'The relevant error-causing widget was:';
    final markerIndex = diagnosticsText.indexOf(marker);
    if (markerIndex == -1) return '';

    final afterMarker = diagnosticsText.substring(markerIndex + marker.length);
    final lines = afterMarker
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return '';
    return _trim(lines.take(3).join(' '), 260);
  }

  static String _trim(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }
}
