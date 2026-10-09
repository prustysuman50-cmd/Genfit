import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/community/accountability_partner.dart';
import 'daily_stats_service.dart';
import 'gamification_service.dart';
import 'user_service.dart';

/// Centralized service managing the Accountability Partner MVP feature.
/// Coordinates mutual daily check-ins, side-by-side progress comparisons,
/// motivational nudges, and local persistence.
class AccountabilityService extends ChangeNotifier {
  AccountabilityService._() {
    UserService.instance.addListener(_onExternalDataChanged);
    GamificationService.instance.addListener(_onExternalDataChanged);
    DailyStatsService.instance.addListener(_onExternalDataChanged);
  }

  static final AccountabilityService instance = AccountabilityService._();

  static const String _fileName = 'genfit_accountability.json';

  AccountabilityPartner _partner = AccountabilityPartner.defaultPartner;
  String? _lastUserCheckInDateKey;
  bool _isInitialized = false;
  String? _customStoragePath;

  AccountabilityPartner get partner => _partner;
  String? get lastUserCheckInDateKey => _lastUserCheckInDateKey;
  bool get isInitialized => _isInitialized;

  void _onExternalDataChanged() {
    notifyListeners();
  }

  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  /// Canonical YYYY-MM-DD date key
  static String getTodayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Whether current user checked in today
  bool isUserCheckedInToday([DateTime? date]) {
    return _lastUserCheckInDateKey == getTodayKey(date);
  }

  /// Whether partner checked in today
  bool get isPartnerCheckedInToday => _partner.isCheckedInToday;

  /// Dynamic mutual accountability message based on pair check-in state
  String get accountabilityMessage {
    final userDone = isUserCheckedInToday();
    final partnerDone = isPartnerCheckedInToday;

    if (userDone && partnerDone) {
      return "Great! You're both staying consistent and keeping each other on track. 🔥";
    } else if (userDone && !partnerDone) {
      return "You checked in! ${_partner.name} hasn't checked in yet. Keep them motivated! 💬";
    } else if (!userDone && partnerDone) {
      return "${_partner.name} is already active today. Don't miss your check-in! ⚡";
    } else {
      return "Neither of you has checked in today yet. Check in to set the pace for your team! 🎯";
    }
  }

  /// Executes today's check-in for the current user.
  /// Prevents duplicate check-ins on the same day.
  /// Awards +20 XP through GamificationService on successful check-in.
  Future<bool> checkInToday({DateTime? date}) async {
    final key = getTodayKey(date);
    if (_lastUserCheckInDateKey == key) {
      // Already checked in today - idempotency guard
      return false;
    }

    _lastUserCheckInDateKey = key;

    // Small consistency check-in reward through existing GamificationService
    await GamificationService.instance.addXp(20);

    await _persist();
    notifyListeners();
    return true;
  }

  /// Sets partner check-in status (useful for demo state switching)
  void setPartnerCheckedIn(bool isCheckedIn) {
    _partner = _partner.copyWith(isCheckedInToday: isCheckedIn);
    notifyListeners();
  }

  /// Initializes the service and restores saved check-in state
  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          _lastUserCheckInDateKey = data['lastUserCheckInDateKey'] as String?;
          if (data['partner'] is Map<String, dynamic>) {
            _partner = AccountabilityPartner.fromJson(
              data['partner'] as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AccountabilityService init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Resets state back to initial defaults (used for testing and data clear)
  Future<void> resetToDefaults() async {
    _lastUserCheckInDateKey = null;
    _partner = AccountabilityPartner.defaultPartner;
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
    notifyListeners();
  }

  // --- Local Persistence ---

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          'lastUserCheckInDateKey': _lastUserCheckInDateKey,
          'partner': _partner.toJson(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('AccountabilityService persist error: $e');
    }
  }

  Future<File?> _getExistingFileOrTarget() async {
    try {
      if (_customStoragePath != null) {
        final dir = Directory(_customStoragePath!);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/$_fileName');
      }

      final candidates = _getCandidateDirectories();

      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      for (final dirPath in candidates) {
        try {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final testFile = File('$dirPath/$_fileName');
          return testFile;
        } catch (_) {
          continue;
        }
      }

      return File('${Directory.systemTemp.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  List<String> _getCandidateDirectories() {
    final list = <String>[];

    if (Platform.isAndroid) {
      final pkg = _getAndroidPackageName() ?? 'com.example.genfit';
      list.addAll([
        '/data/user/0/$pkg/files',
        '/data/data/$pkg/files',
        '/data/user/0/$pkg/app_flutter',
        '/data/data/$pkg/app_flutter',
        '/data/user/0/com.example.genfit/files',
        '/data/data/com.example.genfit/files',
        '/data/user/0/$pkg/cache',
        '/data/data/$pkg/cache',
      ]);
    }

    list.add(Directory.systemTemp.path);
    return list;
  }

  String? _getAndroidPackageName() {
    try {
      final cmd = File('/proc/self/cmdline').readAsStringSync();
      final pkg = cmd.split('\u0000').first.trim();
      if (pkg.isNotEmpty && pkg.contains('.')) return pkg;
    } catch (_) {}
    return null;
  }
}
