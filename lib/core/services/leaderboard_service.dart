import 'package:flutter/foundation.dart';

import '../../data/mock_community_data.dart';
import '../../models/leaderboard/leaderboard_entry.dart';
import 'community_service.dart';
import 'gamification_service.dart';
import 'user_service.dart';

/// Available competition modes for the Social Leaderboard.
enum LeaderboardMode { interHostel, interCollege }

/// Available filter views for the Leaderboard.
enum LeaderboardFilter { campus, friends, weekly, interHostel, interCollege }

/// Central service managing the Social Leaderboard feature.
/// Supports Inter-Hostel and Inter-College modes, deterministic demo participants,
/// live user scoring via GamificationService, and multi-view filtering.
class LeaderboardService extends ChangeNotifier {
  LeaderboardService._() {
    // Re-notify listeners whenever user profile or gamification XP changes
    UserService.instance.addListener(_onExternalDataChanged);
    GamificationService.instance.addListener(_onExternalDataChanged);
    CommunityService.instance.addListener(_onExternalDataChanged);
  }

  static final LeaderboardService instance = LeaderboardService._();

  LeaderboardMode _currentMode = LeaderboardMode.interHostel;
  LeaderboardMode get currentMode => _currentMode;

  LeaderboardFilter _currentFilter = LeaderboardFilter.campus;
  LeaderboardFilter get currentFilter => _currentFilter;

  String? _selectedHostel;
  String? get selectedHostel => _selectedHostel;

  String? _selectedCollege;
  String? get selectedCollege => _selectedCollege;

  void _onExternalDataChanged() {
    notifyListeners();
  }

  /// Sets the active competition mode (Inter-Hostel vs Inter-College)
  void setMode(LeaderboardMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  /// Sets the active leaderboard view filter
  void setFilter(LeaderboardFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      if (filter == LeaderboardFilter.interHostel) {
        _currentMode = LeaderboardMode.interHostel;
      } else if (filter == LeaderboardFilter.interCollege) {
        _currentMode = LeaderboardMode.interCollege;
      }
      notifyListeners();
    }
  }

  /// Sets a specific hostel filter, or null for all hostels
  void setSelectedHostel(String? hostel) {
    if (_selectedHostel != hostel) {
      _selectedHostel = hostel;
      notifyListeners();
    }
  }

  /// Sets a specific college filter, or null for all colleges
  void setSelectedCollege(String? college) {
    if (_selectedCollege != college) {
      _selectedCollege = college;
      notifyListeners();
    }
  }

  /// Resets all filters back to defaults
  void resetFilters() {
    _currentMode = LeaderboardMode.interHostel;
    _currentFilter = LeaderboardFilter.campus;
    _selectedHostel = null;
    _selectedCollege = null;
    notifyListeners();
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

  /// Deterministic realistic hostel mapping for student participants
  static const Map<String, String> _mockHostelMap = {
    'student_ananya': 'Sarojini Naidu Hall',
    'student_rahul': 'Brahmaputra Hall',
    'student_priya': 'Mahanadi Hostel',
    'student_sneha': 'Kharavela Hostel',
    'student_aman': 'APJ Kalam Block',
    'student_subham': 'Marichi Hall',
    'student_rohan': 'Ganga Block',
    'student_pooja': 'Baitarani Hall',
  };

  /// Deterministic realistic college mapping for student participants
  static const Map<String, String> _mockCollegeMap = {
    'student_ananya': 'NIT Rourkela',
    'student_rahul': 'GCEK Kalahandi',
    'student_priya': 'OUTR Bhubaneswar',
    'student_sneha': 'KIIT University',
    'student_aman': 'Silicon University',
    'student_subham': 'CET Bhubaneswar',
    'student_rohan': 'IIIT Bhubaneswar',
    'student_pooja': 'GITA Autonomous',
  };

  /// Builds the current user's LeaderboardEntry dynamically using active services
  LeaderboardEntry _buildCurrentUserEntry({LeaderboardMode? mode}) {
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

    final hostelDisplay = user.hostel.isNotEmpty
        ? user.hostel
        : 'Mahanadi Hostel';
    final collegeDisplay = user.college.isNotEmpty
        ? user.college
        : 'ITER • Bhubaneswar Campus';
    final campusDisplay = user.campus.isNotEmpty
        ? user.campus
        : (user.college.isNotEmpty ? user.college : 'GCEK Kalahandi');

    return LeaderboardEntry(
      id: user.id.isNotEmpty ? user.id : 'current_user',
      name: user.name.isNotEmpty ? user.name : 'Ayush',
      college: collegeDisplay,
      campus: campusDisplay,
      hostel: hostelDisplay,
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

  /// Returns raw entries from mock students with deterministic hostel and college mappings
  List<LeaderboardEntry> _getMockStudentEntries({LeaderboardMode? mode}) {
    final community = CommunityService.instance;
    final initial = MockCommunityData.getInitialStudents();

    return initial.map((student) {
      final liveStudent = community.getStudentById(student.id);
      final isConnected = liveStudent?.isConnected ?? student.isConnected;
      final weeklyXp = _mockWeeklyXpMap[student.id] ?? 250;
      final hostel = _mockHostelMap[student.id] ?? 'Mahanadi Hostel';
      final college = _mockCollegeMap[student.id] ?? student.college;

      return LeaderboardEntry(
        id: student.id,
        name: student.name,
        college: college,
        campus: MockCommunityData.defaultCampusShort,
        hostel: hostel,
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

  /// Returns sorted and ranked leaderboard entries for the specified or current filter and mode
  List<LeaderboardEntry> getEntries({
    LeaderboardFilter? filter,
    LeaderboardMode? mode,
    String? hostelFilter,
    String? collegeFilter,
  }) {
    final activeMode = mode ?? _currentMode;
    final activeFilter = filter ?? _currentFilter;
    final currentUserEntry = _buildCurrentUserEntry(mode: activeMode);
    final mockEntries = _getMockStudentEntries(mode: activeMode);

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

      case LeaderboardFilter.interHostel:
        candidates = [...mockEntries, currentUserEntry];
        break;

      case LeaderboardFilter.interCollege:
        candidates = [...mockEntries, currentUserEntry];
        break;
    }

    // Optional specific hostel filter
    final targetHostel =
        hostelFilter ??
        ((activeFilter == LeaderboardFilter.interHostel ||
                activeMode == LeaderboardMode.interHostel)
            ? _selectedHostel
            : null);
    if (targetHostel != null &&
        targetHostel.isNotEmpty &&
        targetHostel != 'All') {
      candidates = candidates
          .where(
            (e) =>
                e.hostel.toLowerCase().trim() ==
                targetHostel.toLowerCase().trim(),
          )
          .toList();
    }

    // Optional specific college filter
    final targetCollege =
        collegeFilter ??
        ((activeFilter == LeaderboardFilter.interCollege ||
                activeMode == LeaderboardMode.interCollege)
            ? _selectedCollege
            : null);
    if (targetCollege != null &&
        targetCollege.isNotEmpty &&
        targetCollege != 'All') {
      candidates = candidates
          .where(
            (e) => e.college.toLowerCase().trim().contains(
              targetCollege.toLowerCase().trim(),
            ),
          )
          .toList();
    }

    // Sort descending by primary metric (weeklyXp for weekly, xp for campus/hostel/college/friends)
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

  /// Returns the current user's entry with calculated rank under the active or given filter/mode
  LeaderboardEntry getCurrentUserEntry({
    LeaderboardFilter? filter,
    LeaderboardMode? mode,
    String? hostelFilter,
    String? collegeFilter,
  }) {
    final entries = getEntries(
      filter: filter,
      mode: mode,
      hostelFilter: hostelFilter,
      collegeFilter: collegeFilter,
    );
    final match = entries.where((e) => e.isCurrentUser).toList();
    if (match.isNotEmpty) {
      return match.first;
    }
    // Fallback if filtered out
    return _buildCurrentUserEntry(mode: mode).copyWith(rank: entries.length + 1);
  }

  /// Returns current user's numerical rank under the active or given filter/mode
  int getCurrentUserRank({
    LeaderboardFilter? filter,
    LeaderboardMode? mode,
    String? hostelFilter,
    String? collegeFilter,
  }) {
    return getCurrentUserEntry(
      filter: filter,
      mode: mode,
      hostelFilter: hostelFilter,
      collegeFilter: collegeFilter,
    ).rank;
  }

  /// Returns the top 3 podium entries for the active or given filter/mode
  List<LeaderboardEntry> getTopThree({
    LeaderboardFilter? filter,
    LeaderboardMode? mode,
    String? hostelFilter,
    String? collegeFilter,
  }) {
    final entries = getEntries(
      filter: filter,
      mode: mode,
      hostelFilter: hostelFilter,
      collegeFilter: collegeFilter,
    );
    return entries.take(3).toList();
  }

  /// Returns all ranked entries after the top 3 (rank 4 and beyond)
  List<LeaderboardEntry> getRemainingEntries({
    LeaderboardFilter? filter,
    LeaderboardMode? mode,
    String? hostelFilter,
    String? collegeFilter,
  }) {
    final entries = getEntries(
      filter: filter,
      mode: mode,
      hostelFilter: hostelFilter,
      collegeFilter: collegeFilter,
    );
    if (entries.length <= 3) return const [];
    return entries.sublist(3);
  }

  /// Returns distinct hostels available across participants
  List<String> getAvailableHostels() {
    final set = <String>{'All'};
    final entries = [..._getMockStudentEntries(), _buildCurrentUserEntry()];
    for (final e in entries) {
      if (e.hostel.isNotEmpty) set.add(e.hostel);
    }
    return set.toList();
  }

  /// Returns distinct colleges available across participants
  List<String> getAvailableColleges() {
    final set = <String>{'All'};
    final entries = [..._getMockStudentEntries(), _buildCurrentUserEntry()];
    for (final e in entries) {
      if (e.college.isNotEmpty) set.add(e.college);
    }
    return set.toList();
  }
}
