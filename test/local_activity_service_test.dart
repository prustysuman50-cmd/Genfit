import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genfit/core/services/local_activity_service.dart';
import 'package:genfit/models/community/local_activity_spot.dart';

void main() {
  group('LocalActivityService Core Logic Tests', () {
    late Directory tempDir;
    late LocalActivityService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('local_spots_test_');
      service = LocalActivityService.instance;
      service.setCustomStoragePath(tempDir.path);
      await service.resetToDefaults();
    });

    tearDown(() {
      service.setCustomStoragePath(null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Initializes with 6 default curated spots and all category selected', () {
      expect(service.allSpots.length, equals(6));
      expect(service.filteredSpots.length, equals(6));
      expect(service.selectedCategory, equals(ActivitySpotCategory.all));
      expect(service.searchQuery, isEmpty);
      expect(service.favoriteSpotIds, isEmpty);

      final oval = service.getSpotById('spot_gcek_oval');
      expect(oval, isNotNull);
      expect(oval!.name, contains('GCEK Campus Sports Complex'));
      expect(oval.category, equals(ActivitySpotCategory.campus));
      expect(oval.hasTrack, isTrue);
    });

    test('Category filtering correctly groups and filters spots', () {
      // 1. Campus Category (GCEK Oval, West Lawn)
      service.setCategory(ActivitySpotCategory.campus);
      expect(service.filteredSpots.length, equals(2));
      for (final spot in service.filteredSpots) {
        expect(spot.category, equals(ActivitySpotCategory.campus));
      }

      // 2. Open Gym Category (Brahmaputra Calisthenics, Collectorate Open Gym)
      service.setCategory(ActivitySpotCategory.openGym);
      expect(service.filteredSpots.length, equals(2));
      for (final spot in service.filteredSpots) {
        expect(spot.category, equals(ActivitySpotCategory.openGym));
        expect(spot.hasOutdoorGym, isTrue);
      }

      // 3. Park Category (Kalahandi Eco Park)
      service.setCategory(ActivitySpotCategory.park);
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.id, equals('spot_kalahandi_eco_park'));

      // 4. Track Category (Manikeswari Lake Loop)
      service.setCategory(ActivitySpotCategory.track);
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.id, equals('spot_manikeswari_lake_loop'));

      // 5. All Category restores all 6 spots
      service.setCategory(ActivitySpotCategory.all);
      expect(service.filteredSpots.length, equals(6));
    });

    test('Search query filtering works across name, area, facilities, and tags', () {
      // Search by spot name
      service.setSearchQuery('Brahmaputra');
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.id, equals('spot_brahmaputra_calisthenics'));

      // Search by equipment / facility
      service.setSearchQuery('Pull-up');
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.facilities.any((f) => f.contains('Pull-up')), isTrue);

      // Search by tag
      service.setSearchQuery('Calisthenics');
      expect(service.filteredSpots.length, equals(1));

      // Search by area
      service.setSearchQuery('Old Town');
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.id, equals('spot_manikeswari_lake_loop'));

      // Non-matching query returns empty list
      service.setSearchQuery('non_existent_keyword_xyz');
      expect(service.filteredSpots, isEmpty);

      // Reset query
      service.setSearchQuery('');
      expect(service.filteredSpots.length, equals(6));
    });

    test('Combined category and search filtering', () {
      // Set to Campus category
      service.setCategory(ActivitySpotCategory.campus);

      // Search within Campus spots
      service.setSearchQuery('Turf');
      expect(service.filteredSpots.length, equals(1));
      expect(service.filteredSpots.first.id, equals('spot_gcek_oval'));

      // Searching for an Open Gym keyword while in Campus category yields 0
      service.setSearchQuery('Collectorate');
      expect(service.filteredSpots, isEmpty);
    });

    test('Toggle favorite bookmarks and persists across reload', () async {
      final spotId = 'spot_kalahandi_eco_park';

      // Bookmark spot
      await service.toggleFavorite(spotId);
      expect(service.favoriteSpotIds.contains(spotId), isTrue);
      expect(service.getSpotById(spotId)?.isFavorite, isTrue);

      // Verify persistence by re-initializing from file
      await service.init();
      expect(service.favoriteSpotIds.contains(spotId), isTrue);
      expect(service.getSpotById(spotId)?.isFavorite, isTrue);

      // Unbookmark spot
      await service.toggleFavorite(spotId);
      expect(service.favoriteSpotIds.contains(spotId), isFalse);
      expect(service.getSpotById(spotId)?.isFavorite, isFalse);

      // Re-initialize verifies unbookmark persistence
      await service.init();
      expect(service.favoriteSpotIds.contains(spotId), isFalse);
    });

    test('resetToDefaults resets filters, query, and favorites', () async {
      service.setCategory(ActivitySpotCategory.openGym);
      service.setSearchQuery('gym');
      await service.toggleFavorite('spot_brahmaputra_calisthenics');

      expect(service.selectedCategory, equals(ActivitySpotCategory.openGym));
      expect(service.searchQuery, equals('gym'));
      expect(service.favoriteSpotIds.isNotEmpty, isTrue);

      await service.resetToDefaults();

      expect(service.selectedCategory, equals(ActivitySpotCategory.all));
      expect(service.searchQuery, isEmpty);
      expect(service.favoriteSpotIds, isEmpty);
      expect(service.filteredSpots.length, equals(6));
    });

    test('getSpotById returns null for unknown id', () {
      expect(service.getSpotById('non_existent_id'), isNull);
    });
  });
}
