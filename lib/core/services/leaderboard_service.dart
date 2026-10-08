import 'package:flutter/foundation.dart';

import '../../data/mock_community_data.dart';
import '../../models/leaderboard/leaderboard_entry.dart';
import 'community_service.dart';
import 'gamification_service.dart';
import 'user_service.dart';

/// Available filter views for the Campus Leaderboard.
enum LeaderboardFilter { campus, friends, weekly }

/// Central service managing the Campus Leaderboard feature.
/// Provides sorted student rankings, rank calculations, and multi-view filtering (Campus / Friends / Weekly).
class LeaderboardService extends ChangeNotifier {
  LeaderboardService._() {
    // Re-notify listeners whenever user profile or gamification XP changes
    UserService.instance.addListener(_onExternalDataChanged);
    GamificationService.instance.addListener(_onExternalDataChanged);
    CommunityService.instance.addListener(_onExternalDataChanged);
  }

  static final LeaderboardService instance = LeaderboardService._();

  LeaderboardFilter _currentFilter = LeaderboardFilter.campus;
  LeaderboardFilter get currentFilter => _currentFilter;

  void _onExternalDataChanged() {
    notifyListeners();
  }

  /// Sets the active leaderboard view filter
  void setFilter(LeaderboardFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  /// Base weekly XP distribution for mock campus peers
  static const Map<String, int> _mockWeeklyXpMap = {
    'student_ananya': 920,
    'student_rahul': 780,
    'student_priya': 620,
    'student_sneha': 540,
    'student_aman': 390,
    'student_subham': 340,
    'student_rohan': 210,
    'student_pooja': 180,
  };

  /// Builds the current user's LeaderboardEntry dynamically using active services
  LeaderboardEntry _buildCurrentUserEntry() {
    final user = UserService.instance.currentUser;
    final gamification = GamificationService.instance;

    final xp = gamification.xp;
    final level = gamification.currentLevel;
    final levelTitle = gamification.levelTitle;
    final streak = gamification.streakDays;

    // Dynamically calculate weekly XP for the current user
    // (Base 720 XP, dynamically adjusted if user earns more XP)
    final weeklyXp = xp >= 3850
        ? 720 + (xp - 3850)
        : (xp * 0.2).round().clamp(0, 10000);

    final campusDisplay = user.campus.isNotEmpty
        ? user.campus
        : (user.college.isNotEmpty ? user.college : 'GCEK Kalahandi');

    return LeaderboardEntry(
      id: user.id.isNotEmpty ? user.id : 'current_user',
      name: user.name.isNotEmpty ? user.name : 'Ayush',
      college: user.college.isNotEmpty
          ? user.college
          : MockCommunityData.defaultCampusName,
      campus: campusDisplay,
      avatarInitials: user.avatarInitials.isNotEmpty
          ? user.avatarInitials
          : (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'ME'),
      xp: xp,
      weeklyXp: weeklyXp,
      level: level,
      levelTitle: levelTitle,
      streakDays: streak,
      isCurrentUser: true,
      isConnected: true,
      challengesCompleted: gamification.activeChallenge.isCompleted ? 1 : 0,
    );
  }

  /// Returns raw entries from mock students and community service
  List<LeaderboardEntry> _getMockStudentEntries() {
    final community = CommunityService.instance;
    final initial = MockCommunityData.getInitialStudents();

    return initial.map((student) {
      final liveStudent = community.getStudentById(student.id);
      final isConnected = liveStudent?.isConnected ?? student.isConnected;
      final weeklyXp = _mockWeeklyXpMap[student.id] ?? 250;

      return LeaderboardEntry(
        id: student.id,
        name: student.name,
        college: student.college,
        campus: MockCommunityData.defaultCampusShort,
        avatarInitials: student.avatarInitials,
        xp: student.xp,
        weeklyXp: weeklyXp,
        level: student.level,
        levelTitle: student.levelTitle,
        streakDays: student.streakDays,
        isCurrentUser: false,
        isConnected: isConnected,
        challengesCompleted: student.badgeCount,
      );
    }).toList();
  }

  /// Returns sorted and ranked leaderboard entries for the specified or current filter
  List<LeaderboardEntry> getEntries({LeaderboardFilter? filter}) {
    final activeFilter = filter ?? _currentFilter;
    final currentUserEntry = _buildCurrentUserEntry();
    final mockEntries = _getMockStudentEntries();

    List<LeaderboardEntry> candidates;

    switch (activeFilter) {
      case LeaderboardFilter.campus:
        // All campus students + current user
        candidates = [...mockEntries, currentUserEntry];
        break;

      case LeaderboardFilter.friends:
        // Connected peers + current user
        candidates = [
          ...mockEntries.where((e) => e.isConnected),
          currentUserEntry,
        ];
        break;

      case LeaderboardFilter.weekly:
        // All students ranked by weekly XP
        candidates = [...mockEntries, currentUserEntry];
        break;
    }

    // Sort descending by primary metric (weeklyXp for weekly, xp for campus/friends)
    candidates.sort((a, b) {
      final metricA = activeFilter == LeaderboardFilter.weekly
          ? a.weeklyXp
          : a.xp;
      final metricB = activeFilter == LeaderboardFilter.weekly
          ? b.weeklyXp
          : b.xp;

      if (metricB != metricA) {
        return metricB.compareTo(metricA);
      }
      // Secondary sort: Streak days descending
      if (b.streakDays != a.streakDays) {
        return b.streakDays.compareTo(a.streakDays);
      }
      // Tertiary sort: Name alphabetical
      return a.name.compareTo(b.name);
    });

    // Assign sequential ranks (1-indexed)
    final rankedList = <LeaderboardEntry>[];
    for (int i = 0; i < candidates.length; i++) {
      rankedList.add(candidates[i].copyWith(rank: i + 1));
    }

    return List.unmodifiable(rankedList);
  }

  /// Returns the current user's entry with calculated rank under the active or given filter
  LeaderboardEntry getCurrentUserEntry({LeaderboardFilter? filter}) {
    final entries = getEntries(filter: filter);
    final match = entries.where((e) => e.isCurrentUser).toList();
    if (match.isNotEmpty) {
      return match.first;
    }
    // Fallback if not found in list
    return _buildCurrentUserEntry().copyWith(rank: entries.length + 1);
  }

  /// Returns current user's numerical rank under the active or given filter
  int getCurrentUserRank({LeaderboardFilter? filter}) {
    return getCurrentUserEntry(filter: filter).rank;
  }

  /// Returns the top 3 podium entries for the active or given filter
  List<LeaderboardEntry> getTopThree({LeaderboardFilter? filter}) {
    final entries = getEntries(filter: filter);
    return entries.take(3).toList();
  }

  /// Returns all ranked entries after the top 3 (rank 4 and beyond)
  List<LeaderboardEntry> getRemainingEntries({LeaderboardFilter? filter}) {
    final entries = getEntries(filter: filter);
    if (entries.length <= 3) return const [];
    return entries.sublist(3);
  }
}
