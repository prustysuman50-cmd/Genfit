import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/community/local_activity_spot.dart';

/// Central service managing offline-curated nearby fitness spots (parks, tracks, open gyms).
/// Allows filtering by category, search queries, and local favorite bookmarking.
class LocalActivityService extends ChangeNotifier {
  LocalActivityService._() {
    _initSpots();
  }

  static final LocalActivityService instance = LocalActivityService._();

  static const String _fileName = 'genfit_local_spots.json';

  String? _customStoragePath;
  bool _isInitialized = false;

  late List<LocalActivitySpot> _spots;
  ActivitySpotCategory _selectedCategory = ActivitySpotCategory.all;
  String _searchQuery = '';
  final Set<String> _favoriteSpotIds = {};

  bool get isInitialized => _isInitialized;
  ActivitySpotCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  List<LocalActivitySpot> get allSpots => List.unmodifiable(_spots);
  Set<String> get favoriteSpotIds => Set.unmodifiable(_favoriteSpotIds);

  /// Returns spots filtered by the active category and search query.
  List<LocalActivitySpot> get filteredSpots {
    return _spots.where((spot) {
      final matchesCategory = _selectedCategory == ActivitySpotCategory.all ||
          spot.category == _selectedCategory;

      if (!matchesCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;

      final query = _searchQuery.toLowerCase().trim();
      final inName = spot.name.toLowerCase().contains(query);
      final inArea = spot.area.toLowerCase().contains(query);
      final inDesc = spot.shortDescription.toLowerCase().contains(query);
      final inFacilities =
          spot.facilities.any((f) => f.toLowerCase().contains(query));
      final inTags =
          spot.bestForTags.any((t) => t.toLowerCase().contains(query));

      return inName || inArea || inDesc || inFacilities || inTags;
    }).toList();
  }

  /// Sets custom directory for isolated unit tests.
  void setCustomStoragePath(String? path) {
    _customStoragePath = path;
  }

  void _initSpots() {
    _spots = defaultSpots.map((s) {
      return s.copyWith(isFavorite: _favoriteSpotIds.contains(s.id));
    }).toList();
  }

  Future<void> init() async {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['favoriteSpotIds'] is List) {
            _favoriteSpotIds.clear();
            for (final id in data['favoriteSpotIds']) {
              if (id is String) _favoriteSpotIds.add(id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LocalActivityService init error: $e');
    } finally {
      _isInitialized = true;
      _initSpots();
      notifyListeners();
    }
  }

  /// Updates category filter.
  void setCategory(ActivitySpotCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Updates live search query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Toggles favorite bookmark on a spot and persists change locally.
  Future<void> toggleFavorite(String spotId) async {
    if (_favoriteSpotIds.contains(spotId)) {
      _favoriteSpotIds.remove(spotId);
    } else {
      _favoriteSpotIds.add(spotId);
    }

    _initSpots();
    _persistSync();
    notifyListeners();
  }

  /// Retrieves a spot by its ID.
  LocalActivitySpot? getSpotById(String id) {
    final matches = _spots.where((s) => s.id == id).toList();
    if (matches.isNotEmpty) return matches.first;
    return null;
  }

  /// Resets state to default initial conditions (for tests/demo reset).
  Future<void> resetToDefaults() async {
    _selectedCategory = ActivitySpotCategory.all;
    _searchQuery = '';
    _favoriteSpotIds.clear();
    _initSpots();
    _persistSync();
    notifyListeners();
  }

  void _persistSync() {
    try {
      final file = _getExistingFileOrTarget();
      if (file != null) {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }

        final Map<String, dynamic> data = {
          'favoriteSpotIds': _favoriteSpotIds.toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        file.writeAsStringSync(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('LocalActivityService persist error: $e');
    }
  }

  File? _getExistingFileOrTarget() {
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
          return File('$dirPath/$_fileName');
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

  /// Curated demo dataset representing student-friendly outdoor activity spots.
  static const List<LocalActivitySpot> defaultSpots = [
    LocalActivitySpot(
      id: 'spot_gcek_oval',
      name: 'GCEK Campus Sports Complex & Oval',
      category: ActivitySpotCategory.campus,
      area: 'GCEK Kalahandi Main Campus',
      shortDescription:
          'Official university sports ground featuring an all-weather 400m running track, central grass field, and sprint straightaways.',
      distanceDemo: '0.1 km • On campus (demo)',
      distanceKmDemo: 0.1,
      hasTrack: true,
      hasOpenSpace: true,
      hasOutdoorGym: false,
      facilities: [
        '400m Athletics Track',
        'Stretching Turf',
        'Sprint Lanes',
        'Night Floodlights',
        'Drinking Water Point',
      ],
      equipmentList: [
        'Agility Hurdle Sets',
        'Sprint Cones',
        'Stretching Mats',
      ],
      bestForTags: ['Interval Runs', 'Morning Jogs', 'Sprint Drills'],
      timings: '5:30 AM – 9:00 PM • Free Student Access',
      surfaceType: 'Cinder/Clay Track & Grass Turf',
      safetyTip: 'Floodlights active until 8:30 PM; college security booth nearby.',
    ),
    LocalActivitySpot(
      id: 'spot_brahmaputra_calisthenics',
      name: 'Brahmaputra Hostel Calisthenics Zone',
      category: ActivitySpotCategory.openGym,
      area: 'East Quadrangle, GCEK Hostels',
      shortDescription:
          'Dedicated open-air bodyweight training station constructed for hostel residents. Perfect for pull-ups, dips, and push-ups.',
      distanceDemo: '0.2 km • On campus (demo)',
      distanceKmDemo: 0.2,
      hasOutdoorGym: true,
      hasTrack: false,
      hasOpenSpace: true,
      facilities: [
        'Triple-height Pull-up Bars',
        'Parallel Dip Stations',
        'Incline Abdominal Bench',
        'Rubberised Impact Turf',
      ],
      equipmentList: [
        'High Pull-up Bar',
        'Parallel Dip Bars',
        'Swedish Wall Ladder',
        'Push-up Bars',
      ],
      bestForTags: ['Calisthenics', 'Upper Body Strength', 'Quick HIIT'],
      timings: 'Open 24/7 • Hostel Resident Priority',
      surfaceType: 'Recycled Rubber Floor & Sand Base',
      safetyTip: 'Check bar grip when wet after morning dew or monsoon showers.',
    ),
    LocalActivitySpot(
      id: 'spot_kalahandi_eco_park',
      name: 'Kalahandi Eco Park & Fitness Trail',
      category: ActivitySpotCategory.park,
      area: 'Bhawanipatna Civil Lines',
      shortDescription:
          'Scenic public eco park with a tree-shaded jogging loop, peaceful yoga lawn, and a municipal outdoor fitness equipment cluster.',
      distanceDemo: '1.4 km from campus (demo)',
      distanceKmDemo: 1.4,
      hasOutdoorGym: true,
      hasTrack: true,
      hasOpenSpace: true,
      facilities: [
        '1.2 km Paved Jogging Loop',
        'Open Gym Machinery',
        'Yoga Grass Pavilion',
        'Rest Benches & Shade',
      ],
      equipmentList: [
        'Air Walker / Elliptical',
        'Double Chest Press',
        'Seated Leg Press',
        'Torso Twister Rig',
      ],
      bestForTags: ['Long Distance Walks', 'Open-air Yoga', 'Cardio Circuit'],
      timings: '5:00 AM – 8:30 PM • Free Public Access',
      surfaceType: 'Interlocking Paver Path & Lawn',
      safetyTip: 'Most peaceful between 5:30 AM and 7:00 AM before city traffic starts.',
    ),
    LocalActivitySpot(
      id: 'spot_collectorate_open_gym',
      name: 'Collectorate Green Park Open Gym',
      category: ActivitySpotCategory.openGym,
      area: 'Town Administrative Zone, Bhawanipatna',
      shortDescription:
          'Community open-air gym equipped with public fitness machines in a peaceful municipal park surrounded by neem and sal trees.',
      distanceDemo: '2.1 km from campus (demo)',
      distanceKmDemo: 2.1,
      hasOutdoorGym: true,
      hasTrack: false,
      hasOpenSpace: true,
      facilities: [
        '8-Station Outdoor Gym',
        'Walking Pathways',
        'Covered Pavilion',
      ],
      equipmentList: [
        'Seated Rowing Machine',
        'Shoulder Builder Rig',
        'Waist Twister Disk',
        'Double Leg Extender',
      ],
      bestForTags: ['Low-impact Mobility', 'Resistance Circuit', 'Evening Walks'],
      timings: '5:30 AM – 9:00 PM • Free Access',
      surfaceType: 'Concrete Platform with Mats',
      safetyTip: 'Inspect mechanical joints before loading full body weight.',
    ),
    LocalActivitySpot(
      id: 'spot_manikeswari_lake_loop',
      name: 'Manikeswari Temple Lake Loop',
      category: ActivitySpotCategory.track,
      area: 'Old Town Heritage Corridor',
      shortDescription:
          'A classic circular lakeside running track with measured distance markers and refreshing lake breeze along the water perimeter.',
      distanceDemo: '2.8 km from campus (demo)',
      distanceKmDemo: 2.8,
      hasTrack: true,
      hasOpenSpace: true,
      hasOutdoorGym: false,
      facilities: [
        '1.8 km Perimetric Running Loop',
        'Distance Interval Markers',
        'Waterfront Breeze Corridor',
      ],
      equipmentList: [
        'Kilometer / 100m Distance Markers',
      ],
      bestForTags: ['Sunset Running', 'Tempo Runs', 'Endurance Walks'],
      timings: 'Open 24/7 • Well-lit until 10:00 PM',
      surfaceType: 'Compacted Red Clay & Stone Border',
      safetyTip: 'Wear trail or running shoes with decent tread for clay path.',
    ),
    LocalActivitySpot(
      id: 'spot_college_west_lawn',
      name: 'College West Lawn & Agility Area',
      category: ActivitySpotCategory.campus,
      area: 'Academic Block B Grounds',
      shortDescription:
          'Wide manicured open lawn used by college sports teams for bodyweight conditioning, yoga sessions, and cool-down mobility.',
      distanceDemo: '0.1 km • On campus (demo)',
      distanceKmDemo: 0.1,
      hasOpenSpace: true,
      hasTrack: false,
      hasOutdoorGym: false,
      facilities: [
        'Expansive Bermuda Grass Lawn',
        'Plyometric Step Stairs',
        'Natural Shade Canopy',
      ],
      equipmentList: [
        'Staircase Step Training',
      ],
      bestForTags: ['Agility Drills', 'Group Workouts', 'Cool-down Stretches'],
      timings: '6:00 AM – 7:30 PM • Free Student Access',
      surfaceType: 'Natural Bermuda Grass Lawn',
      safetyTip: 'Great for barefoot mobility and post-workout static stretches.',
    ),
  ];
}
