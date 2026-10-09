/// Represents a student entry on the GenFit Campus Leaderboard.
class LeaderboardEntry {
  final String id;
  final String name;
  final String college;
  final String campus;
  final String hostel;
  final String avatarInitials;
  final int xp;
  final int weeklyXp;
  final int level;
  final String levelTitle;
  final int streakDays;
  final int rank;
  final bool isCurrentUser;
  final bool isConnected;
  final int challengesCompleted;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    this.college = 'Government College of Engineering, Kalahandi',
    this.campus = 'GCEK Kalahandi',
    this.hostel = 'Mahanadi Hostel',
    required this.avatarInitials,
    required this.xp,
    this.weeklyXp = 0,
    required this.level,
    required this.levelTitle,
    required this.streakDays,
    this.rank = 0,
    this.isCurrentUser = false,
    this.isConnected = false,
    this.challengesCompleted = 0,
  });

  LeaderboardEntry copyWith({
    String? id,
    String? name,
    String? college,
    String? campus,
    String? hostel,
    String? avatarInitials,
    int? xp,
    int? weeklyXp,
    int? level,
    String? levelTitle,
    int? streakDays,
    int? rank,
    bool? isCurrentUser,
    bool? isConnected,
    int? challengesCompleted,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      campus: campus ?? this.campus,
      hostel: hostel ?? this.hostel,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      xp: xp ?? this.xp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      streakDays: streakDays ?? this.streakDays,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isConnected: isConnected ?? this.isConnected,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'college': college,
    'campus': campus,
    'hostel': hostel,
    'avatarInitials': avatarInitials,
    'xp': xp,
    'weeklyXp': weeklyXp,
    'level': level,
    'levelTitle': levelTitle,
    'streakDays': streakDays,
    'rank': rank,
    'isCurrentUser': isCurrentUser,
    'isConnected': isConnected,
    'challengesCompleted': challengesCompleted,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        college: json['college'] as String? ?? '',
        campus: json['campus'] as String? ?? '',
        hostel: json['hostel'] as String? ??
            (json['hostelName'] as String?) ??
            'Mahanadi Hostel',
        avatarInitials: json['avatarInitials'] as String? ?? '',
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        weeklyXp: (json['weeklyXp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        levelTitle: json['levelTitle'] as String? ?? 'Campus Rookie',
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
        isConnected: json['isConnected'] as bool? ?? false,
        challengesCompleted:
            (json['challengesCompleted'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() =>
      'LeaderboardEntry(rank: $rank, name: $name, hostel: $hostel, college: $college, xp: $xp, weeklyXp: $weeklyXp, level: $level, isCurrentUser: $isCurrentUser)';
}
