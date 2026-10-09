import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/models/community/local_activity_spot.dart';

void main() {
  group('LocalActivitySpot Model Tests', () {
    test('creates LocalActivitySpot with correct fields and defaults', () {
      const spot = LocalActivitySpot(
        id: 'spot_test',
        name: 'GCEK Fitness Pavilion',
        category: ActivitySpotCategory.campus,
        area: 'Main Campus',
        shortDescription: 'Student outdoor training zone',
        distanceDemo: '0.2 km from campus (demo)',
        distanceKmDemo: 0.2,
        facilities: ['Pull-up Bars', 'Parallel Dips'],
        equipmentList: ['High Bar', 'Dip Station'],
        hasOutdoorGym: true,
        hasTrack: false,
        hasOpenSpace: true,
        bestForTags: ['Calisthenics', 'Upper Body'],
      );

      expect(spot.id, equals('spot_test'));
      expect(spot.name, equals('GCEK Fitness Pavilion'));
      expect(spot.category, equals(ActivitySpotCategory.campus));
      expect(spot.area, equals('Main Campus'));
      expect(spot.distanceKmDemo, equals(0.2));
      expect(spot.facilities.length, equals(2));
      expect(spot.equipmentList.length, equals(2));
      expect(spot.hasOutdoorGym, isTrue);
      expect(spot.hasTrack, isFalse);
      expect(spot.hasOpenSpace, isTrue);
      expect(spot.isFavorite, isFalse);
    });

    test('supports copyWith modifying specific fields', () {
      const original = LocalActivitySpot(
        id: 'spot_test',
        name: 'Eco Park',
        category: ActivitySpotCategory.park,
        area: 'Civil Lines',
        shortDescription: 'Green park',
        distanceDemo: '1.0 km (demo)',
        distanceKmDemo: 1.0,
      );

      final updated = original.copyWith(
        name: 'Kalahandi Eco Park',
        isFavorite: true,
        hasTrack: true,
      );

      expect(updated.id, equals('spot_test'));
      expect(updated.name, equals('Kalahandi Eco Park'));
      expect(updated.isFavorite, isTrue);
      expect(updated.hasTrack, isTrue);
      expect(original.name, equals('Eco Park'));
      expect(original.isFavorite, isFalse);
    });

    test('serializes to and deserializes from JSON correctly', () {
      const spot = LocalActivitySpot(
        id: 'spot_collectorate',
        name: 'Collectorate Open Gym',
        category: ActivitySpotCategory.openGym,
        area: 'Town Administrative Zone',
        shortDescription: 'Community outdoor fitness rig',
        distanceDemo: '2.1 km (demo)',
        distanceKmDemo: 2.1,
        facilities: ['8-Station Gym', 'Walking Pavers'],
        equipmentList: ['Leg Press', 'Rowing Machine'],
        hasOutdoorGym: true,
        hasTrack: false,
        hasOpenSpace: true,
        bestForTags: ['Mobility', 'Evening Workout'],
        isFavorite: true,
      );

      final json = spot.toJson();
      expect(json['id'], equals('spot_collectorate'));
      expect(json['category'], equals('openGym'));
      expect(json['distanceKmDemo'], equals(2.1));
      expect(json['isFavorite'], isTrue);

      final restored = LocalActivitySpot.fromJson(json);
      expect(restored.id, equals(spot.id));
      expect(restored.name, equals(spot.name));
      expect(restored.category, equals(spot.category));
      expect(restored.facilities, equals(spot.facilities));
      expect(restored.equipmentList, equals(spot.equipmentList));
      expect(restored.hasOutdoorGym, isTrue);
      expect(restored.isFavorite, isTrue);
    });

    test('ActivitySpotCategory enum parsing handles various inputs', () {
      expect(ActivitySpotCategory.fromString('openGym'), ActivitySpotCategory.openGym);
      expect(ActivitySpotCategory.fromString('open_gym'), ActivitySpotCategory.openGym);
      expect(ActivitySpotCategory.fromString('track'), ActivitySpotCategory.track);
      expect(ActivitySpotCategory.fromString('tracks'), ActivitySpotCategory.track);
      expect(ActivitySpotCategory.fromString('park'), ActivitySpotCategory.park);
      expect(ActivitySpotCategory.fromString('parks'), ActivitySpotCategory.park);
      expect(ActivitySpotCategory.fromString('campus'), ActivitySpotCategory.campus);
      expect(ActivitySpotCategory.fromString('unknown'), ActivitySpotCategory.all);
    });
  });
}
