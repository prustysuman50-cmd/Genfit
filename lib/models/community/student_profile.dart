class StudentProfile {
  final String id;
  final String name;
  final String avatarInitials;
  final String college;
  final int level;
  final String levelTitle;
  final int xp;
  final int streakDays;
  final String fitnessStatus;
  final String currentActivity;
  final bool isConnected;
  final DateTime? connectedAt;
  final int badgeCount;

  const StudentProfile({
    required this.id,
    required this.name,
    required this.avatarInitials,
    this.college = 'Government College of Engineering, Kalahandi (GCEK)',
    required this.level,
    required this.levelTitle,
    required this.xp,
    required this.streakDays,
    required this.fitnessStatus,
    required this.currentActivity,
    this.isConnected = false,
    this.connectedAt,
    this.badgeCount = 3,
  });

  String get firstName => name.split(' ').first;

  StudentProfile copyWith({
    String? id,
    String? name,
    String? avatarInitials,
    String? college,
    int? level,
    String? levelTitle,
    int? xp,
    int? streakDays,
    String? fitnessStatus,
    String? currentActivity,
    bool? isConnected,
    DateTime? connectedAt,
    int? badgeCount,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      college: college ?? this.college,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      fitnessStatus: fitnessStatus ?? this.fitnessStatus,
      currentActivity: currentActivity ?? this.currentActivity,
      isConnected: isConnected ?? this.isConnected,
      connectedAt: connectedAt ?? this.connectedAt,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarInitials': avatarInitials,
    'college': college,
    'level': level,
    'levelTitle': levelTitle,
    'xp': xp,
    'streakDays': streakDays,
    'fitnessStatus': fitnessStatus,
    'currentActivity': currentActivity,
    'isConnected': isConnected,
    'connectedAt': connectedAt?.toIso8601String(),
    'badgeCount': badgeCount,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarInitials: json['avatarInitials'] as String,
    college:
        (json['college'] as String?) ??
        'Government College of Engineering, Kalahandi (GCEK)',
    level: (json['level'] as num).toInt(),
    levelTitle: (json['levelTitle'] as String?) ?? 'Campus Warrior',
    xp: (json['xp'] as num).toInt(),
    streakDays: (json['streakDays'] as num).toInt(),
    fitnessStatus: json['fitnessStatus'] as String,
    currentActivity: json['currentActivity'] as String,
    isConnected: (json['isConnected'] as bool?) ?? false,
    connectedAt: json['connectedAt'] != null
        ? DateTime.parse(json['connectedAt'] as String)
        : null,
    badgeCount: (json['badgeCount'] as num?)?.toInt() ?? 3,
  );
}
