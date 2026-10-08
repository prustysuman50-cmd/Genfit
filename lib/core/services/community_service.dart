import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/mock_community_data.dart';
import '../../models/community/community_activity.dart';
import '../../models/community/student_profile.dart';

class CommunityService extends ChangeNotifier {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  static const String _fileName = 'genfit_community.json';

  List<StudentProfile> _students = [];
  List<CommunityActivity> _activities = [];
  final Set<String> _connectedStudentIds = {};
  bool _isInitialized = false;
  String? _customStoragePath;

  bool get isInitialized => _isInitialized;
  String get campusName => MockCommunityData.defaultCampusName;
  String get campusShortName => MockCommunityData.defaultCampusShort;

  List<StudentProfile> get allStudents => List.unmodifiable(_students);
  List<StudentProfile> get campusStudents => List.unmodifiable(_students);
  List<StudentProfile> get friends =>
      _students.where((s) => s.isConnected).toList();
  List<CommunityActivity> get activities => List.unmodifiable(_activities);

  int get friendsCount => friends.length;
  int get campusCount => _students.length;

  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  Future<void> init() async {
    _students = MockCommunityData.getInitialStudents();
    _activities = MockCommunityData.getInitialActivities();

    try {
      final file = await _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['connectedStudentIds'] is List) {
            _connectedStudentIds.clear();
            for (final id in data['connectedStudentIds']) {
              if (id is String) {
                _connectedStudentIds.add(id);
              }
            }
          }
        }
      } else {
        // Default initial connected state from mock data
        for (final s in _students) {
          if (s.isConnected) {
            _connectedStudentIds.add(s.id);
          }
        }
      }

      // Apply connected IDs to students list
      _applyConnections();
    } catch (e) {
      debugPrint('CommunityService init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _applyConnections() {
    _students = _students.map((student) {
      final connected = _connectedStudentIds.contains(student.id);
      return student.copyWith(
        isConnected: connected,
        connectedAt: connected ? (student.connectedAt ?? DateTime.now()) : null,
      );
    }).toList();
  }

  StudentProfile? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleConnection(String studentId) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;

    final student = _students[index];
    final newConnected = !student.isConnected;

    if (newConnected) {
      _connectedStudentIds.add(studentId);
    } else {
      _connectedStudentIds.remove(studentId);
    }

    _students[index] = student.copyWith(
      isConnected: newConnected,
      connectedAt: newConnected ? DateTime.now() : null,
    );

    await _persist();
    notifyListeners();
  }

  Future<void> connectStudent(String studentId) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;

    final student = _students[index];
    if (student.isConnected) return;

    _connectedStudentIds.add(studentId);
    _students[index] = student.copyWith(
      isConnected: true,
      connectedAt: DateTime.now(),
    );

    await _persist();
    notifyListeners();
  }

  Future<void> disconnectStudent(String studentId) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;

    final student = _students[index];
    if (!student.isConnected) return;

    _connectedStudentIds.remove(studentId);
    _students[index] = student.copyWith(isConnected: false, connectedAt: null);

    await _persist();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _students = MockCommunityData.getInitialStudents();
    _activities = MockCommunityData.getInitialActivities();
    _connectedStudentIds.clear();
    for (final s in _students) {
      if (s.isConnected) {
        _connectedStudentIds.add(s.id);
      }
    }
    _applyConnections();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final file = await _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final Map<String, dynamic> data = {
          'connectedStudentIds': _connectedStudentIds.toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('CommunityService persist error: $e');
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
