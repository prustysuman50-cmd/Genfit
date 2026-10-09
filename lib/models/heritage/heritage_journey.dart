import 'heritage_milestone.dart';

/// Represents a curated virtual Odisha Heritage Journey converting daily campus
/// steps into cultural fitness expeditions.
class HeritageJourney {
  final String id;
  final String title;
  final String startLandmark;
  final String destinationLandmark;
  final String region;
  final String shortDescription;
  final double totalDistanceKm;
  final List<HeritageMilestone> milestones;
  final int completionRewardXp;
  final String? completionBadgeId;
  final String? completionBadgeName;

  const HeritageJourney({
    required this.id,
    required this.title,
    required this.startLandmark,
    required this.destinationLandmark,
    required this.region,
    required this.shortDescription,
    required this.totalDistanceKm,
    required this.milestones,
    this.completionRewardXp = 250,
    this.completionBadgeId,
    this.completionBadgeName,
  });

  HeritageJourney copyWith({
    String? id,
    String? title,
    String? startLandmark,
    String? destinationLandmark,
    String? region,
    String? shortDescription,
    double? totalDistanceKm,
    List<HeritageMilestone>? milestones,
    int? completionRewardXp,
    String? completionBadgeId,
    String? completionBadgeName,
  }) {
    return HeritageJourney(
      id: id ?? this.id,
      title: title ?? this.title,
      startLandmark: startLandmark ?? this.startLandmark,
      destinationLandmark: destinationLandmark ?? this.destinationLandmark,
      region: region ?? this.region,
      shortDescription: shortDescription ?? this.shortDescription,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      milestones: milestones ?? this.milestones,
      completionRewardXp: completionRewardXp ?? this.completionRewardXp,
      completionBadgeId: completionBadgeId ?? this.completionBadgeId,
      completionBadgeName: completionBadgeName ?? this.completionBadgeName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startLandmark': startLandmark,
    'destinationLandmark': destinationLandmark,
    'region': region,
    'shortDescription': shortDescription,
    'totalDistanceKm': totalDistanceKm,
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'completionRewardXp': completionRewardXp,
    'completionBadgeId': completionBadgeId,
    'completionBadgeName': completionBadgeName,
  };

  factory HeritageJourney.fromJson(Map<String, dynamic> json) =>
      HeritageJourney(
        id: json['id'] as String,
        title: json['title'] as String,
        startLandmark: json['startLandmark'] as String,
        destinationLandmark: json['destinationLandmark'] as String,
        region: json['region'] as String? ?? 'Odisha, India',
        shortDescription: json['shortDescription'] as String? ?? '',
        totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((m) => HeritageMilestone.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        completionRewardXp:
            (json['completionRewardXp'] as num?)?.toInt() ?? 250,
        completionBadgeId: json['completionBadgeId'] as String?,
        completionBadgeName: json['completionBadgeName'] as String?,
      );

  /// Primary showcase route: Lingaraj Temple -> Konark Sun Temple (65.0 km)
  static const HeritageJourney showcaseLingarajToKonark = HeritageJourney(
    id: 'heritage_lingaraj_konark',
    title: 'Lingaraj Temple → Konark Sun Temple',
    startLandmark: 'Lingaraj Temple (Bhubaneswar)',
    destinationLandmark: 'Konark Sun Temple',
    region: 'Khordha & Puri Districts, Coastal Odisha',
    shortDescription:
        'Walk through the Golden Triangle: from the 11th-century Kalinga sanctuary of Lingaraj, past Ashokan peace monuments and artisan villages, culminating at the UNESCO World Heritage Sun Temple.',
    totalDistanceKm: 65.0,
    completionRewardXp: 250,
    completionBadgeId: 'odisha_heritage_champion',
    completionBadgeName: 'Golden Triangle Finisher',
    milestones: [
      HeritageMilestone(
        id: 'lingaraj_start',
        name: 'Lingaraj Temple',
        landmark: 'Ekamra Kshetra, Old Town Bhubaneswar',
        shortDescription:
            '11th-century architectural marvel dedicated to Lord Harihara. Starting sanctum of your spiritual and fitness expedition.',
        requiredDistanceKm: 0.0,
        requiredSteps: 0,
        visualIdentifier: 'lingaraj_temple',
        rewardXp: 0,
        isUnlocked: true,
        isCompleted: true,
      ),
      HeritageMilestone(
        id: 'dhauli_stupa',
        name: 'Dhauli Shanti Stupa',
        landmark: 'Dhauli Hills, Daya River Basin',
        shortDescription:
            'Historic Peace Pagoda atop Dhauli Hills where Emperor Ashoka embraced Ahimsa (non-violence) following the Kalinga War.',
        requiredDistanceKm: 8.5,
        requiredSteps: 8500,
        visualIdentifier: 'shanti_stupa',
        rewardXp: 100,
        badgeId: 'dhauli_peace_badge',
        badgeName: 'Peace of Dhauli',
        isUnlocked: false,
        isCompleted: false,
      ),
      HeritageMilestone(
        id: 'pipili_village',
        name: 'Pipili Applique Craft Village',
        landmark: 'Pipili Heritage Artisan Corridor',
        shortDescription:
            'World-famed Odia artisan hub renowned for brilliant Chandua cloth canopies, temple umbrellas, and colourful patchwork crafts.',
        requiredDistanceKm: 20.0,
        requiredSteps: 20000,
        visualIdentifier: 'pipili_craft',
        rewardXp: 100,
        badgeId: 'pipili_artisan_badge',
        badgeName: 'Pipili Master Artisan',
        isUnlocked: false,
        isCompleted: false,
      ),
      HeritageMilestone(
        id: 'nimapada_stop',
        name: 'Nimapada Heritage Stop',
        landmark: 'Nimapada Town, Prachi Valley',
        shortDescription:
            'Celebrated trading junction along the ancient Prachi River Valley, world-famous for heritage Chenapoda and Odia sweet delicacies.',
        requiredDistanceKm: 42.0,
        requiredSteps: 42000,
        visualIdentifier: 'nimapada_heritage',
        rewardXp: 100,
        badgeId: 'nimapada_sweets_badge',
        badgeName: 'Prachi Valley Pioneer',
        isUnlocked: false,
        isCompleted: false,
      ),
      HeritageMilestone(
        id: 'konark_sun_temple',
        name: 'Konark Sun Temple',
        landmark: 'Konark, Bay of Bengal Coast',
        shortDescription:
            '13th-century monumental stone chariot of the Sun God Surya featuring 24 intricate carved wheels. UNESCO World Heritage treasure.',
        requiredDistanceKm: 65.0,
        requiredSteps: 65000,
        visualIdentifier: 'sun_temple',
        rewardXp: 100,
        badgeId: 'konark_champion_badge',
        badgeName: 'Konark Surya Champion',
        isUnlocked: false,
        isCompleted: false,
      ),
    ],
  );

  /// Second curated route: Puri Jagannath -> Chilika Lake (50.0 km)
  static const HeritageJourney showcasePuriToChilika = HeritageJourney(
    id: 'heritage_puri_chilika',
    title: 'Puri Jagannath → Chilika Lake',
    startLandmark: 'Shree Jagannath Temple (Puri)',
    destinationLandmark: 'Chilika Lake (Satapada)',
    region: 'Puri District, Coastal Lagoon Corridor',
    shortDescription:
        'Traverse from the sacred ocean shores of Lord Jagannath Dham through sacred Brahmagiri to Asia’s largest brackish lagoon at Satapada.',
    totalDistanceKm: 50.0,
    completionRewardXp: 200,
    completionBadgeId: 'coastal_lagoon_finisher',
    completionBadgeName: 'Chilika Explorer Finisher',
    milestones: [
      HeritageMilestone(
        id: 'puri_jagannath_start',
        name: 'Shree Jagannath Temple',
        landmark: 'Bada Danda, Puri Ocean Coast',
        shortDescription:
            'Sacred 12th-century Dham of Mahaprabhu Jagannath, Balabhadra, and Subhadra on the Bay of Bengal.',
        requiredDistanceKm: 0.0,
        requiredSteps: 0,
        visualIdentifier: 'puri_temple',
        rewardXp: 0,
        isUnlocked: true,
        isCompleted: true,
      ),
      HeritageMilestone(
        id: 'brahmagiri_alarnath',
        name: 'Brahmagiri Alarnath Temple',
        landmark: 'Brahmagiri Holy Shrine',
        shortDescription:
            'Historic medieval shrine where devotees congregate during the sacred Anavasara period of Ratha Yatra.',
        requiredDistanceKm: 25.0,
        requiredSteps: 25000,
        visualIdentifier: 'alarnath_shrine',
        rewardXp: 100,
        badgeId: 'alarnath_pilgrim_badge',
        badgeName: 'Brahmagiri Pilgrim',
        isUnlocked: false,
        isCompleted: false,
      ),
      HeritageMilestone(
        id: 'chilika_satapada',
        name: 'Chilika Lake (Satapada)',
        landmark: 'Satapada Dolphin Sanctuary',
        shortDescription:
            'Asia’s largest brackish water lake sanctuary, home to rare Irrawaddy dolphins and thousands of migratory birds.',
        requiredDistanceKm: 50.0,
        requiredSteps: 50000,
        visualIdentifier: 'chilika_lagoon',
        rewardXp: 100,
        badgeId: 'chilika_explorer_badge',
        badgeName: 'Chilika Dolphin Voyager',
        isUnlocked: false,
        isCompleted: false,
      ),
    ],
  );

  static List<HeritageJourney> get defaultJourneys => [
        showcaseLingarajToKonark,
        showcasePuriToChilika,
      ];
}
