/// Prevents the app from stacking duplicate alarm gate routes for the same
/// alarm while a gate/challenge flow is already active.
///
/// This is intentionally tiny and in-memory only. It does not replace alarm
/// scheduling state; it only protects navigation while the app is open.
class AlarmGateRouteGuard {
  static int? _activeDbAlarmId;
  static int? _activeRuntimeAlarmId;

  static bool isActiveForDbAlarm(int dbAlarmId) =>
      _activeDbAlarmId == dbAlarmId;

  static void markActive({required int dbAlarmId, required int runtimeAlarmId}) {
    _activeDbAlarmId = dbAlarmId;
    _activeRuntimeAlarmId = runtimeAlarmId;
  }

  static void clearForDbAlarm(int dbAlarmId) {
    if (_activeDbAlarmId != dbAlarmId) return;
    _activeDbAlarmId = null;
    _activeRuntimeAlarmId = null;
  }

  static String debugLabel() {
    final db = _activeDbAlarmId;
    final runtime = _activeRuntimeAlarmId;
    if (db == null) return 'none';
    return 'db=$db runtime=$runtime';
  }
}
