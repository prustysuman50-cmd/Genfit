import 'dart:convert';
import 'dart:io';

import '../../models/onboarding_profile.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  bool _isOnboardingCompleted = false;
  OnboardingProfile? _profile;

  bool get isOnboardingCompleted => _isOnboardingCompleted;
  OnboardingProfile? get profile => _profile;

  static const String _fileName = 'genfit_onboarding.json';

  Future<void> init() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> json = jsonDecode(content);
          _profile = OnboardingProfile.fromJson(json);
          _isOnboardingCompleted = _profile?.isCompleted ?? false;
        }
      }
    } catch (_) {
      // Graceful fallback to default in-memory state
    }
  }

  Future<void> saveProfile(OnboardingProfile profile) async {
    _profile = profile;
    _isOnboardingCompleted = profile.isCompleted;

    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsStringSync(jsonEncode(profile.toJson()), flush: true);
      }
    } catch (_) {
      // Preserved in-memory
    }
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _isOnboardingCompleted = completed;
    if (_profile != null) {
      _profile = _profile!.copyWith(isCompleted: completed);
      await saveProfile(_profile!);
    } else {
      _profile = OnboardingProfile(isCompleted: completed);
      await saveProfile(_profile!);
    }
  }

  Future<void> resetOnboarding() async {
    _isOnboardingCompleted = false;
    _profile = null;
    try {
      final files = await _getAllPossibleFiles();
      for (final file in files) {
        if (file.existsSync()) {
          try {
            file.writeAsStringSync('', flush: true);
            file.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {
      // Ignored
    }
  }

  Future<File?> _getExistingFileOrTarget() async {
    try {
      final candidates = _getCandidateDirectories();

      // First check if an existing saved file exists in any candidate directory
      for (final dirPath in candidates) {
        final file = File('$dirPath/$_fileName');
        if (file.existsSync()) {
          return file;
        }
      }

      // If no file exists yet, return the first writable directory
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

  Future<List<File>> _getAllPossibleFiles() async {
    final files = <File>[];
    for (final dirPath in _getCandidateDirectories()) {
      try {
        files.add(File('$dirPath/$_fileName'));
      } catch (_) {}
    }
    return files;
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
