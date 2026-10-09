/// Represents a peer accountability partner in GenFit.
class AccountabilityPartner {
  final String id;
  final String name;
  final String avatarInitials;
  final String college;
  final String hostel;
  final int level;
  final String levelTitle;
  final int xp;
  final int streakDays;
  final int todaySteps;
  final bool todayWorkoutCompleted;
  final bool isCheckedInToday;
  final DateTime? lastCheckInDate;
  final String motivationalNote;

  const AccountabilityPartner({
    required this.id,
    required this.name,
    required this.avatarInitials,
    this.college = 'GCEK Kalahandi',
    this.hostel = 'Brahmaputra Hall',
    required this.level,
    required this.levelTitle,
    required this.xp,
    required this.streakDays,
    this.todaySteps = 6420,
    this.todayWorkoutCompleted = true,
    this.isCheckedInToday = true,
    this.lastCheckInDate,
    this.motivationalNote = 'Stay hard! Consistency beats talent every single day.',
  });

  /// Deterministic default accountability partner for the MVP
  static const AccountabilityPartner defaultPartner = AccountabilityPartner(
    id: 'partner_rahul',
    name: 'Rahul Patel',
    avatarInitials: 'RP',
    college: 'GCEK Kalahandi',
    hostel: 'Brahmaputra Hall',
    level: 5,
    levelTitle: 'Desi Beast',
    xp: 4120,
    streakDays: 9,
    todaySteps: 6420,
    todayWorkoutCompleted: true,
    isCheckedInToday: true,
    motivationalNote: 'Crushed hostel room HIIT! Keep the streak alive, let’s win this.',
  );

  AccountabilityPartner copyWith({
    String? id,
    String? name,
    String? avatarInitials,
    String? college,
    String? hostel,
    int? level,
    String? levelTitle,
    int? xp,
    int? streakDays,
    int? todaySteps,
    bool? todayWorkoutCompleted,
    bool? isCheckedInToday,
    DateTime? lastCheckInDate,
    String? motivationalNote,
  }) {
    return AccountabilityPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      college: college ?? this.college,
      hostel: hostel ?? this.hostel,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      todaySteps: todaySteps ?? this.todaySteps,
      todayWorkoutCompleted:
          todayWorkoutCompleted ?? this.todayWorkoutCompleted,
      isCheckedInToday: isCheckedInToday ?? this.isCheckedInToday,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      motivationalNote: motivationalNote ?? this.motivationalNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarInitials': avatarInitials,
    'college': college,
    'hostel': hostel,
    'level': level,
    'levelTitle': levelTitle,
    'xp': xp,
    'streakDays': streakDays,
    'todaySteps': todaySteps,
    'todayWorkoutCompleted': todayWorkoutCompleted,
    'isCheckedInToday': isCheckedInToday,
    'lastCheckInDate': lastCheckInDate?.toIso8601String(),
    'motivationalNote': motivationalNote,
  };

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) =>
      AccountabilityPartner(
        id: json['id'] as String? ?? 'partner_rahul',
        name: json['name'] as String? ?? 'Rahul Patel',
        avatarInitials: json['avatarInitials'] as String? ?? 'RP',
        college: json['college'] as String? ?? 'GCEK Kalahandi',
        hostel: json['hostel'] as String? ?? 'Brahmaputra Hall',
        level: (json['level'] as num?)?.toInt() ?? 5,
        levelTitle: json['levelTitle'] as String? ?? 'Desi Beast',
        xp: (json['xp'] as num?)?.toInt() ?? 4120,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 9,
        todaySteps: (json['todaySteps'] as num?)?.toInt() ?? 6420,
        todayWorkoutCompleted:
            json['todayWorkoutCompleted'] as bool? ?? true,
        isCheckedInToday: json['isCheckedInToday'] as bool? ?? true,
        lastCheckInDate: json['lastCheckInDate'] != null
            ? DateTime.tryParse(json['lastCheckInDate'] as String)
            : null,
        motivationalNote: json['motivationalNote'] as String? ??
            'Stay hard! Consistency beats talent every single day.',
      );
}
