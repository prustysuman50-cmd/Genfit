import 'package:flutter/material.dart';

/// Categories for outdoor and campus fitness activity spots.
enum ActivitySpotCategory {
  all,
  openGym,
  track,
  park,
  campus;

  String get displayName {
    switch (this) {
      case ActivitySpotCategory.all:
        return 'All Spots';
      case ActivitySpotCategory.openGym:
        return 'Open Gyms';
      case ActivitySpotCategory.track:
        return 'Tracks';
      case ActivitySpotCategory.park:
        return 'Parks';
      case ActivitySpotCategory.campus:
        return 'Campus';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivitySpotCategory.all:
        return Icons.grid_view_rounded;
      case ActivitySpotCategory.openGym:
        return Icons.fitness_center_rounded;
      case ActivitySpotCategory.track:
        return Icons.directions_run_rounded;
      case ActivitySpotCategory.park:
        return Icons.park_rounded;
      case ActivitySpotCategory.campus:
        return Icons.school_rounded;
    }
  }

  static ActivitySpotCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'opengym':
      case 'open_gym':
        return ActivitySpotCategory.openGym;
      case 'track':
      case 'tracks':
        return ActivitySpotCategory.track;
      case 'park':
      case 'parks':
        return ActivitySpotCategory.park;
      case 'campus':
        return ActivitySpotCategory.campus;
      default:
        return ActivitySpotCategory.all;
    }
  }
}

/// Represents an offline-curated park, track, or open gym spot for student fitness.
class LocalActivitySpot {
  final String id;
  final String name;
  final ActivitySpotCategory category;
  final String area;
  final String shortDescription;
  final String distanceDemo;
  final double distanceKmDemo;
  final List<String> facilities;
  final List<String> equipmentList;
  final bool hasOutdoorGym;
  final bool hasTrack;
  final bool hasOpenSpace;
  final List<String> bestForTags;
  final String timings;
  final String surfaceType;
  final String safetyTip;
  final bool isFavorite;

  const LocalActivitySpot({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.shortDescription,
    required this.distanceDemo,
    required this.distanceKmDemo,
    this.facilities = const [],
    this.equipmentList = const [],
    this.hasOutdoorGym = false,
    this.hasTrack = false,
    this.hasOpenSpace = true,
    this.bestForTags = const [],
    this.timings = 'Open 24/7 • Free Access',
    this.surfaceType = 'All-weather',
    this.safetyTip = 'Good daytime lighting; stay hydrated during training.',
    this.isFavorite = false,
  });

  LocalActivitySpot copyWith({
    String? id,
    String? name,
    ActivitySpotCategory? category,
    String? area,
    String? shortDescription,
    String? distanceDemo,
    double? distanceKmDemo,
    List<String>? facilities,
    List<String>? equipmentList,
    bool? hasOutdoorGym,
    bool? hasTrack,
    bool? hasOpenSpace,
    List<String>? bestForTags,
    String? timings,
    String? surfaceType,
    String? safetyTip,
    bool? isFavorite,
  }) {
    return LocalActivitySpot(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      area: area ?? this.area,
      shortDescription: shortDescription ?? this.shortDescription,
      distanceDemo: distanceDemo ?? this.distanceDemo,
      distanceKmDemo: distanceKmDemo ?? this.distanceKmDemo,
      facilities: facilities ?? this.facilities,
      equipmentList: equipmentList ?? this.equipmentList,
      hasOutdoorGym: hasOutdoorGym ?? this.hasOutdoorGym,
      hasTrack: hasTrack ?? this.hasTrack,
      hasOpenSpace: hasOpenSpace ?? this.hasOpenSpace,
      bestForTags: bestForTags ?? this.bestForTags,
      timings: timings ?? this.timings,
      surfaceType: surfaceType ?? this.surfaceType,
      safetyTip: safetyTip ?? this.safetyTip,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'area': area,
    'shortDescription': shortDescription,
    'distanceDemo': distanceDemo,
    'distanceKmDemo': distanceKmDemo,
    'facilities': facilities,
    'equipmentList': equipmentList,
    'hasOutdoorGym': hasOutdoorGym,
    'hasTrack': hasTrack,
    'hasOpenSpace': hasOpenSpace,
    'bestForTags': bestForTags,
    'timings': timings,
    'surfaceType': surfaceType,
    'safetyTip': safetyTip,
    'isFavorite': isFavorite,
  };

  factory LocalActivitySpot.fromJson(Map<String, dynamic> json) =>
      LocalActivitySpot(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ActivitySpotCategory.fromString(
          json['category'] as String? ?? 'all',
        ),
        area: json['area'] as String? ?? '',
        shortDescription: json['shortDescription'] as String? ?? '',
        distanceDemo: json['distanceDemo'] as String? ?? 'Demo distance',
        distanceKmDemo: (json['distanceKmDemo'] as num?)?.toDouble() ?? 1.0,
        facilities: (json['facilities'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        equipmentList: (json['equipmentList'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        hasOutdoorGym: json['hasOutdoorGym'] as bool? ?? false,
        hasTrack: json['hasTrack'] as bool? ?? false,
        hasOpenSpace: json['hasOpenSpace'] as bool? ?? true,
        bestForTags: (json['bestForTags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        timings: json['timings'] as String? ?? 'Open 24/7 • Free Access',
        surfaceType: json['surfaceType'] as String? ?? 'All-weather',
        safetyTip: json['safetyTip'] as String? ??
            'Good daytime lighting; stay hydrated during training.',
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  @override
  String toString() =>
      'LocalActivitySpot(id: $id, name: $name, category: ${category.name}, distance: $distanceDemo)';
}
