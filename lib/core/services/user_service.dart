import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/onboarding_profile.dart';
import '../../models/user_profile.dart';
import 'storage_service.dart';

/// Centralized service providing the single source of truth for the current
/// GenFit user's profile, personal metrics, college identity, and fitness preferences.
class UserService extends ChangeNotifier {
  UserService._();

  static final UserService instance = UserService._();

  static const String _fileName = 'genfit_user_profile.json';

  UserProfile _currentUser = UserProfile.defaultUser;
  bool _isInitialized = false;
  String? _customStoragePath;

  UserProfile get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> json = jsonDecode(content);
          _currentUser = UserProfile.fromJson(json);
          _isInitialized = true;
          notifyListeners();
          return;
        }
      }

      // If no dedicated user profile file exists yet, check if onboarding
      // was previously completed in StorageService and inherit those values
      final onboardingProfile = StorageService.instance.profile;
      if (onboardingProfile != null) {
        _currentUser = UserProfile.fromOnboarding(
          onboardingProfile,
          base: _currentUser,
        );
        await _saveToFile();
      }
    } catch (e) {
      debugPrint('UserService.init error: $e');
      // Preserves default in-memory profile
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    await _saveToFile();
    notifyListeners();
  }

  Future<void> updateFields({
    String? id,
    String? name,
    String? college,
    String? campus,
    String? hostel,
    String? avatarInitials,
    int? streakDays,
    int? xp,
    int? level,
    String? levelTitle,
    int? nextLevelXp,
    double? customLevelProgress,
    int? age,
    double? heightCm,
    double? weightKg,
    String? fitnessGoal,
    String? fitnessLevel,
    String? dietPreference,
    String? budgetPreference,
    String? workoutLocation,
    List<String>? equipment,
    List<String>? motivations,
    String? journeyPreference,
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    _currentUser = _currentUser.copyWith(
      id: id,
      name: name,
      college: college,
      campus: campus,
      hostel: hostel,
      avatarInitials: avatarInitials,
      streakDays: streakDays,
      xp: xp,
      level: level,
      levelTitle: levelTitle,
      nextLevelXp: nextLevelXp,
      customLevelProgress: customLevelProgress,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      fitnessGoal: fitnessGoal,
      fitnessLevel: fitnessLevel,
      dietPreference: dietPreference,
      budgetPreference: budgetPreference,
      workoutLocation: workoutLocation,
      equipment: equipment,
      motivations: motivations,
      journeyPreference: journeyPreference,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );

    await _saveToFile();
    notifyListeners();
  }

  Future<void> syncFromOnboarding(OnboardingProfile onboarding) async {
    _currentUser = UserProfile.fromOnboarding(onboarding, base: _currentUser);
    await _saveToFile();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _currentUser = UserProfile.defaultUser;
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveToFile() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsStringSync(jsonEncode(_currentUser.toJson()), flush: true);
      }
    } catch (e) {
      debugPrint('UserService._saveToFile error: $e');
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

      // Check if file already exists in candidate
      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      // Return first writable candidate
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
