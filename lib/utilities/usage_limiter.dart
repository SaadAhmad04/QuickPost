// lib/utils/usage_limiter.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageLimiter with WidgetsBindingObserver {
  UsageLimiter._private();
  static final UsageLimiter instance = UsageLimiter._private();

  // private keys (kept private)
  static const _kAccSeconds = 'qp_acc_seconds';
  static const _kAccDate = 'qp_acc_date';
  static const _kLimitSeconds = 'qp_limit_seconds';
  static const _kBlockedDate = 'qp_blocked_date';
  static const _kAutoLogout = 'qp_auto_logout';

  SharedPreferences? _prefs;
  DateTime? _sessionStart;
  Timer? _tickTimer;

  /// Callback when limit reached — host app should present blocking UI / logout
  void Function()? onLimitReached;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _prefs = await SharedPreferences.getInstance();
    print('[UsageLimiter] init: prefs loaded');
    _resetIfNewDay();
  }

  // Expose prefs if necessary (nullable)
  Future<SharedPreferences?> getPrefs() async {
    return _prefs;
  }

  // Public API: set/get auto logout
  Future<void> setAutoLogout(bool value) async {
    await _prefs?.setBool(_kAutoLogout, value);
  }

  bool getAutoLogout() {
    return _prefs?.getBool(_kAutoLogout) ?? false;
  }

  // Public API: reset today's counters & blocked flag (for debug / admin)
  Future<void> resetToday() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    final today = _todayString();
    await _prefs?.setInt(_kAccSeconds, 0);
    await _prefs?.setString(_kAccDate, today);
    await _prefs?.remove(_kBlockedDate);
    print('[UsageLimiter] resetToday -> cleared acc / blocked flag for $today');
  }

  // User sets limit (in seconds)
  Future<void> setLimitSeconds(int seconds) async {
    await _prefs?.setInt(_kLimitSeconds, seconds);
    print('[UsageLimiter] setLimitSeconds=$seconds');
  }

  int getLimitSeconds() {
    return _prefs?.getInt(_kLimitSeconds) ?? 0;
  }

  // Start session (foreground)
  void startSession() {
    if (isBlockedToday()) {
      print('[UsageLimiter] startSession skipped — blocked today');
      return;
    }
    _resetIfNewDay();
    _sessionStart = DateTime.now();
    _startTick();
    print('[UsageLimiter] startSession at $_sessionStart');
  }

  // Stop session and persist delta seconds.
  Future<void> stopSession() async {
    if (_sessionStart == null) return;
    final now = DateTime.now();
    Duration delta = now.difference(_sessionStart!);

    final startDateStr = _dateString(_sessionStart!);
    final nowDateStr = _dateString(now);

    if (startDateStr == nowDateStr) {
      await _addSeconds(delta.inSeconds);
    } else {
      final midnight = DateTime(_sessionStart!.year, _sessionStart!.month, _sessionStart!.day).add(Duration(days:1));
      final part1 = midnight.difference(_sessionStart!).inSeconds;
      final part2 = now.difference(midnight).inSeconds;
      await _addSeconds(part1);
      await _setAccSecondsForDate(nowDateStr, part2);
    }

    _sessionStart = null;
    _stopTick();
    print('[UsageLimiter] stopSession delta=${delta.inSeconds}s');
  }

  Future<void> _addSeconds(int s) async {
    _resetIfNewDay();
    final curr = _prefs?.getInt(_kAccSeconds) ?? 0;
    final newVal = curr + s;
    await _prefs?.setInt(_kAccSeconds, newVal);
    await _prefs?.setString(_kAccDate, _todayString());
    print('[UsageLimiter] accumulated now=$newVal s for date=${_prefs?.getString(_kAccDate)}');
    _checkLimitAndMaybeBlock(newVal);
  }

  Future<void> _setAccSecondsForDate(String dateStr, int seconds) async {
    await _prefs?.setInt(_kAccSeconds, seconds);
    await _prefs?.setString(_kAccDate, dateStr);
    print('[UsageLimiter] setAccSeconds for $dateStr = $seconds');
    _checkLimitAndMaybeBlock(seconds);
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _checkCurrentSessionAgainstLimit();
    });
  }

  void _stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _checkCurrentSessionAgainstLimit() {
    if (_sessionStart == null) return;
    final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
    final acc = _prefs?.getInt(_kAccSeconds) ?? 0;
    final total = acc + elapsed;
    final limit = getLimitSeconds();
    print('[UsageLimiter] tick acc=$acc elapsed=$elapsed total=$total limit=$limit');

    if (limit > 0 && total >= limit) {
      final over = total - limit;
      final secondsToStore = acc + (elapsed - over);
      _prefs?.setInt(_kAccSeconds, secondsToStore);
      _prefs?.setString(_kAccDate, _todayString());
      _prefs?.setString(_kBlockedDate, _todayString());
      _stopTick();
      _sessionStart = null;
      print('[UsageLimiter] LIMIT REACHED — blocked for today');
      if (onLimitReached != null) onLimitReached!();
    }
  }

  void _checkLimitAndMaybeBlock(int totalSeconds) {
    final limit = getLimitSeconds();
    if (limit > 0 && totalSeconds >= limit) {
      _prefs?.setString(_kBlockedDate, _todayString());
      print('[UsageLimiter] _checkLimitAndMaybeBlock -> blocked');
      if (onLimitReached != null) onLimitReached!();
    }
  }

  bool isBlockedToday() {
    final d = _prefs?.getString(_kBlockedDate);
    final today = _todayString();
    final blocked = d == today;
    if (blocked) print('[UsageLimiter] isBlockedToday=TRUE');
    return blocked;
  }

  int getAccumulatedSeconds() {
    _resetIfNewDay();
    return _prefs?.getInt(_kAccSeconds) ?? 0;
  }

  void _resetIfNewDay() {
    final savedDate = _prefs?.getString(_kAccDate);
    final today = _todayString();
    if (savedDate == null || savedDate != today) {
      _prefs?.setInt(_kAccSeconds, 0);
      _prefs?.setString(_kAccDate, today);
      final blockedDate = _prefs?.getString(_kBlockedDate);
      if (blockedDate != today) _prefs?.remove(_kBlockedDate);
      print('[UsageLimiter] Day changed — reset counters to 0 for date=$today');
    }
  }

  String _todayString() => _dateString(DateTime.now());
  String _dateString(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[UsageLimiter] lifecycle state=$state');
    if (state == AppLifecycleState.resumed) {
      startSession();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      stopSession();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTick();
  }
}
