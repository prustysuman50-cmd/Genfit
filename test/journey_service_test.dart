import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/journey_service.dart';
import 'package:genfit/models/journey/journey_destination.dart';

void main() {
  group('JourneyDestination Model Tests', () {
    test(
      'creates JourneyDestination with correct default and custom fields',
      () {
        const dest = JourneyDestination(
          id: 'test_dest',
          name: 'Dhauli Peace Pagoda',
          shortDescription: 'Historic Buddhist landmark',
          distanceKm: 8.5,
          requiredProgress: 8.5,
          visualIdentifier: 'shanti_stupa',
          isUnlocked: true,
          isCompleted: false,
        );

        expect(dest.id, equals('test_dest'));
        expect(dest.name, equals('Dhauli Peace Pagoda'));
        expect(dest.shortDescription, equals('Historic Buddhist landmark'));
        expect(dest.distanceKm, equals(8.5));
        expect(dest.requiredProgress, equals(8.5));
        expect(dest.visualIdentifier, equals('shanti_stupa'));
        expect(dest.isUnlocked, isTrue);
        expect(dest.isCompleted, isFalse);
      },
    );

    test('supports copyWith modifying specific fields', () {
      const original = JourneyDestination(
        id: 'dest_cuttack',
        name: 'Cuttack',
        shortDescription: 'Silver City',
        distanceKm: 28.0,
        requiredProgress: 28.0,
      );

      final updated = original.copyWith(isUnlocked: true, isCompleted: true);

      expect(updated.id, equals('dest_cuttack'));
      expect(updated.name, equals('Cuttack'));
      expect(updated.isUnlocked, isTrue);
      expect(updated.isCompleted, isTrue);
      expect(original.isUnlocked, isFalse);
    });

    test('serializes to and deserializes from JSON correctly', () {
      const dest = JourneyDestination(
        id: 'dest_konark',
        name: 'Konark',
        shortDescription: 'The Sun Temple',
        distanceKm: 65.0,
        requiredProgress: 93.0,
        visualIdentifier: 'sun_temple',
        isUnlocked: true,
        isCompleted: false,
      );

      final json = dest.toJson();
      expect(json['id'], equals('dest_konark'));
      expect(json['requiredProgress'], equals(93.0));
      expect(json['visualIdentifier'], equals('sun_temple'));

      final restored = JourneyDestination.fromJson(json);
      expect(restored.id, equals(dest.id));
      expect(restored.name, equals(dest.name));
      expect(restored.shortDescription, equals(dest.shortDescription));
      expect(restored.distanceKm, equals(dest.distanceKm));
      expect(restored.requiredProgress, equals(dest.requiredProgress));
      expect(restored.visualIdentifier, equals(dest.visualIdentifier));
      expect(restored.isUnlocked, equals(dest.isUnlocked));
      expect(restored.isCompleted, equals(dest.isCompleted));
    });
  });

  group('JourneyService Core Logic Tests', () {
    late Directory tempDir;
    late JourneyService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('journey_test_');
      service = JourneyService.instance;
      service.setCustomStoragePath(tempDir.path);
      await service.resetToDefaults();
    });

    tearDown(() {
      service.setCustomStoragePath(null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initializes with 4 canonical Odisha milestones', () {
      final destinations = service.destinations;
      expect(destinations.length, equals(4));

      expect(destinations[0].id, equals('dest_bhubaneswar'));
      expect(destinations[0].name, equals('Bhubaneswar'));
      expect(destinations[0].distanceKm, equals(0.0));
      expect(destinations[0].requiredProgress, equals(0.0));
      expect(destinations[0].isCompleted, isTrue);
      expect(destinations[0].isUnlocked, isTrue);

      expect(destinations[1].id, equals('dest_cuttack'));
      expect(destinations[1].name, equals('Cuttack'));
      expect(destinations[1].distanceKm, equals(28.0));
      expect(destinations[1].requiredProgress, equals(28.0));
      expect(destinations[1].isCompleted, isFalse);
      expect(
        destinations[1].isUnlocked,
        isTrue,
      ); // First uncompleted is unlocked

      expect(destinations[2].id, equals('dest_konark'));
      expect(destinations[2].name, equals('Konark'));
      expect(destinations[2].distanceKm, equals(65.0));
      expect(destinations[2].requiredProgress, equals(93.0));
      expect(destinations[2].isCompleted, isFalse);
      expect(
        destinations[2].isUnlocked,
        isFalse,
      ); // Locked until Cuttack completed

      expect(destinations[3].id, equals('dest_puri'));
      expect(destinations[3].name, equals('Puri'));
      expect(destinations[3].distanceKm, equals(35.0));
      expect(destinations[3].requiredProgress, equals(128.0));
      expect(destinations[3].isCompleted, isFalse);
      expect(destinations[3].isUnlocked, isFalse);
    });

    test('initial state calculates correct current and next destination', () {
      expect(service.currentProgressKm, equals(0.0));
      expect(service.totalRouteDistanceKm, equals(128.0));
      expect(service.progressPercent, equals(0.0));

      expect(service.currentDestination.id, equals('dest_cuttack'));
      expect(service.nextDestination?.id, equals('dest_konark'));

      expect(service.completedDestinations.length, equals(1));
      expect(service.unlockedDestinations.length, equals(2));

      expect(service.isDestinationCompleted('dest_bhubaneswar'), isTrue);
      expect(service.isDestinationCompleted('dest_cuttack'), isFalse);
      expect(service.isDestinationUnlocked('dest_cuttack'), isTrue);
      expect(service.isDestinationUnlocked('dest_konark'), isFalse);
      expect(service.distanceRemainingTo('dest_cuttack'), equals(28.0));
    });

    test('addProgress increments distance and updates remaining km', () async {
      await service.addProgress(10.0);
      expect(service.currentProgressKm, equals(10.0));
      expect(service.distanceRemainingTo('dest_cuttack'), equals(18.0));
      expect(service.isDestinationCompleted('dest_cuttack'), isFalse);

      await service.addProgress(18.0);
      expect(service.currentProgressKm, equals(28.0));
      expect(service.distanceRemainingTo('dest_cuttack'), equals(0.0));
      expect(service.isDestinationCompleted('dest_cuttack'), isTrue);

      // Now Konark should be the active target and unlocked
      expect(service.currentDestination.id, equals('dest_konark'));
      expect(service.isDestinationUnlocked('dest_konark'), isTrue);
      expect(service.isDestinationUnlocked('dest_puri'), isFalse);
      expect(service.distanceRemainingTo('dest_konark'), equals(65.0));
    });

    test('setProgress updates absolute progress correctly', () async {
      await service.setProgress(95.0);
      expect(service.currentProgressKm, equals(95.0));

      expect(service.isDestinationCompleted('dest_bhubaneswar'), isTrue);
      expect(service.isDestinationCompleted('dest_cuttack'), isTrue);
      expect(service.isDestinationCompleted('dest_konark'), isTrue);
      expect(service.isDestinationCompleted('dest_puri'), isFalse);

      expect(service.currentDestination.id, equals('dest_puri'));
      expect(service.nextDestination, isNull);
      expect(service.isDestinationUnlocked('dest_puri'), isTrue);
      expect(service.distanceRemainingTo('dest_puri'), equals(33.0));
    });

    test(
      'completeDestination advances progress directly to target destination',
      () async {
        await service.completeDestination('dest_konark');
        expect(service.currentProgressKm, equals(93.0));
        expect(service.isDestinationCompleted('dest_konark'), isTrue);
        expect(service.isDestinationUnlocked('dest_puri'), isTrue);
        expect(service.currentDestination.id, equals('dest_puri'));
      },
    );

    test('completing entire route marks all destinations completed and progress at 100%', () async {
      await service.setProgress(128.0);
      expect(service.currentProgressKm, equals(128.0));
      expect(service.progressPercent, equals(1.0));
      expect(service.completedDestinations.length, equals(4));
      expect(service.unlockedDestinations.length, equals(4));
      expect(service.currentDestination.id, equals('dest_puri'));
      expect(service.nextDestination, isNull);
    });

    test('persists state to disk and restores on init()', () async {
      await service.setProgress(50.0);
      expect(service.currentProgressKm, equals(50.0));

      // Re-initialize service pointing to the same storage
      await service.init();
      expect(service.currentProgressKm, equals(50.0));
      expect(service.isDestinationCompleted('dest_cuttack'), isTrue);
      expect(service.isDestinationCompleted('dest_konark'), isFalse);
      expect(service.isDestinationUnlocked('dest_konark'), isTrue);
      expect(service.currentDestination.id, equals('dest_konark'));
    });

    test('resetToDefaults resets progress back to 0.0 and defaults', () async {
      await service.setProgress(100.0);
      expect(service.currentProgressKm, equals(100.0));

      await service.resetToDefaults();
      expect(service.currentProgressKm, equals(0.0));
      expect(service.completedDestinations.length, equals(1));
      expect(service.currentDestination.id, equals('dest_cuttack'));
    });
  });
}
