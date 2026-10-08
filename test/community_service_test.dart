import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/community_service.dart';
import 'package:genfit/models/community/community_activity.dart';
import 'package:genfit/models/community/student_profile.dart';

void main() {
  late Directory tempDir;
  final service = CommunityService.instance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('community_test_');
    service.setCustomStoragePath(tempDir.path);
    await service.resetToDefaults();
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Community Mock Data Loading Tests', () {
    test('loads GCEK students and campus details', () {
      expect(service.campusName, contains('Kalahandi'));
      expect(service.campusShortName, 'GCEK Kalahandi');
      expect(service.campusStudents.length, greaterThanOrEqualTo(8));

      final names = service.campusStudents.map((s) => s.name).toList();
      expect(names, contains('Rahul Patel'));
      expect(names, contains('Priya Sharma'));
      expect(names, contains('Aman Mohapatra'));
      expect(names, contains('Sneha Behera'));
      expect(names, contains('Rohan Sahoo'));
      expect(names, contains('Ananya Nayak'));
      expect(names, contains('Subham Dash'));
      expect(names, contains('Pooja Mishra'));
    });

    test('loads initial community fitness activities', () {
      final activities = service.activities;
      expect(activities.length, greaterThanOrEqualTo(6));

      final actions = activities.map((a) => a.actionText).toList();
      expect(actions, contains('completed a workout'));
      expect(actions, contains('reached a 7 day streak'));
      expect(actions, contains('started the 100 Squats challenge'));
      expect(actions, contains("logged today's meal"));
      expect(actions, contains('finished 10K Steps challenge'));
    });
  });

  group('StudentProfile & CommunityActivity Models Tests', () {
    test('StudentProfile model serialization and helper getters', () {
      const student = StudentProfile(
        id: 'student_test',
        name: 'Bijay Kumar',
        avatarInitials: 'BK',
        college: 'GCEK Kalahandi',
        level: 4,
        levelTitle: 'Campus Warrior',
        xp: 3200,
        streakDays: 8,
        fitnessStatus: "Completed today's workout",
        currentActivity: 'Hostel Room HIIT',
        isConnected: true,
      );

      expect(student.firstName, 'Bijay');

      final json = student.toJson();
      final roundtrip = StudentProfile.fromJson(json);

      expect(roundtrip.id, student.id);
      expect(roundtrip.name, student.name);
      expect(roundtrip.firstName, 'Bijay');
      expect(roundtrip.level, 4);
      expect(roundtrip.xp, 3200);
      expect(roundtrip.streakDays, 8);
      expect(roundtrip.isConnected, isTrue);
    });

    test('CommunityActivity model serialization and timeAgo helper', () {
      final now = DateTime.now();
      final activity = CommunityActivity(
        id: 'act_test',
        studentId: 'student_test',
        studentName: 'Bijay Kumar',
        studentInitials: 'BK',
        studentLevel: 4,
        actionText: 'completed a workout',
        activityDetail: 'Hostel Room HIIT • +100 XP',
        timestamp: now.subtract(const Duration(minutes: 15)),
        activityType: 'workout',
      );

      expect(activity.timeAgo, '15m ago');
      expect(activity.icon, isNotNull);
      expect(activity.iconColor, isNotNull);

      final json = activity.toJson();
      final roundtrip = CommunityActivity.fromJson(json);

      expect(roundtrip.id, activity.id);
      expect(roundtrip.studentName, activity.studentName);
      expect(roundtrip.actionText, activity.actionText);
      expect(roundtrip.activityType, 'workout');
    });
  });

  group('Connect / Disconnect Local State Tests', () {
    test(
      'toggleConnection toggles connected state and updates friends list',
      () async {
        // Find an unconnected student
        final aman = service.getStudentById('student_aman')!;
        expect(aman.isConnected, isFalse);
        final initialFriendsCount = service.friendsCount;

        // Connect Aman
        await service.toggleConnection('student_aman');
        final updatedAman = service.getStudentById('student_aman')!;
        expect(updatedAman.isConnected, isTrue);
        expect(service.friendsCount, initialFriendsCount + 1);
        expect(service.friends.map((s) => s.id), contains('student_aman'));

        // Disconnect Aman
        await service.toggleConnection('student_aman');
        final disconnectedAman = service.getStudentById('student_aman')!;
        expect(disconnectedAman.isConnected, isFalse);
        expect(service.friendsCount, initialFriendsCount);
        expect(
          service.friends.map((s) => s.id),
          isNot(contains('student_aman')),
        );
      },
    );

    test('connectStudent and disconnectStudent work idempotently', () async {
      await service.connectStudent('student_rohan');
      expect(service.getStudentById('student_rohan')?.isConnected, isTrue);

      // Re-connecting does not create duplicate entries
      await service.connectStudent('student_rohan');
      expect(service.getStudentById('student_rohan')?.isConnected, isTrue);

      await service.disconnectStudent('student_rohan');
      expect(service.getStudentById('student_rohan')?.isConnected, isFalse);
    });
  });

  group('Local Persistence Roundtrip Tests', () {
    test(
      'connected student IDs persist to disk and reload on restart',
      () async {
        // Connect Aman and Rohan
        await service.connectStudent('student_aman');
        await service.connectStudent('student_rohan');
        expect(service.friends.map((s) => s.id), contains('student_aman'));
        expect(service.friends.map((s) => s.id), contains('student_rohan'));

        // Verify file exists on disk
        final file = File('${tempDir.path}/genfit_community.json');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content, contains('student_aman'));
        expect(content, contains('student_rohan'));

        // Simulate app restart by re-initializing service
        await service.init();

        expect(service.getStudentById('student_aman')?.isConnected, isTrue);
        expect(service.getStudentById('student_rohan')?.isConnected, isTrue);
        expect(service.friends.map((s) => s.id), contains('student_aman'));
        expect(service.friends.map((s) => s.id), contains('student_rohan'));
      },
    );
  });
}
