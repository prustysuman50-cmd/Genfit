import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/daily_metric.dart';
import '../models/challenge.dart';

class MockData {
  MockData._();

  static const UserProfile currentUser = UserProfile(
    id: 'user_01',
    name: 'Ayush',
    college: 'ITER • Bhubaneswar Campus',
    avatarInitials: 'AK',
    streakDays: 7,
    xp: 3850,
    level: 4,
    levelTitle: 'Campus Warrior',
    nextLevelXp: 5000,
  );

  static const DailyMetrics initialDailyMetrics = DailyMetrics(
    steps: 7420,
    stepsGoal: 10000,
    waterLiters: 2.2,
    waterGoalLiters: 3.0,
    caloriesBurned: 480,
    caloriesGoal: 650,
    activeMinutes: 38,
    activeMinutesGoal: 45,
  );

  static const Workout todaysWorkout = Workout(
    id: 'w_today',
    title: 'Hostel Room High-Burn HIIT',
    category: 'Full Body & Core',
    durationMinutes: 20,
    calories: 220,
    intensity: 'Intermediate',
    exercisesCount: 5,
    equipment: 'No Equipment (Dorm Friendly)',
    tags: ['AI Vision Ready', 'Cardio', 'Core', 'Fat Burn'],
  );

  static const Challenge todaysChallenge = Challenge(
    id: 'c_today',
    title: 'Campus Steps Sprint',
    description: 'Walk 3,000 active steps between college classes today',
    rewardXp: 150,
    progress: 2150,
    target: 3000,
    unit: 'steps',
    category: 'Daily Quest',
    timeLeft: '4 hours left',
  );

  static const List<Workout> workoutLibrary = [
    Workout(
      id: 'w_01',
      title: 'AI Squat & Posture Form Check',
      category: 'Lower Body & AI Vision',
      durationMinutes: 15,
      calories: 140,
      intensity: 'Beginner',
      exercisesCount: 4,
      equipment: 'Phone Camera',
      tags: ['AI Pose Estimation', 'Rep Counter', 'Form Feedback'],
    ),
    Workout(
      id: 'w_02',
      title: 'Desi Dand & Push-Up Power',
      category: 'Upper Body Strength',
      durationMinutes: 18,
      calories: 190,
      intensity: 'Intermediate',
      exercisesCount: 5,
      equipment: 'Bodyweight',
      tags: ['Traditional', 'Chest', 'Triceps'],
    ),
    Workout(
      id: 'w_03',
      title: 'Surya Namaskar 12-Flow',
      category: 'Mobility & Recovery',
      durationMinutes: 12,
      calories: 95,
      intensity: 'All Levels',
      exercisesCount: 12,
      equipment: 'Yoga Mat / Floor',
      tags: ['Morning Energy', 'Flexibility'],
    ),
  ];

  static const List<Map<String, dynamic>> nutritionQuickItems = [
    {
      'title': 'Bhubaneswar Sattu Power Shake',
      'protein': '22g Protein',
      'cost': '₹25 / serving',
      'tag': 'Hostel Friendly',
      'icon': 'local_drink',
    },
    {
      'title': 'High-Protein Odia Dalma Bowl',
      'protein': '18g Protein',
      'cost': '₹35 / serving',
      'tag': 'Mess Alternative',
      'icon': 'rice_bowl',
    },
    {
      'title': 'Roasted Chana & Sprout Chaat',
      'protein': '14g Protein',
      'cost': '₹15 / serving',
      'tag': 'Exam Snack',
      'icon': 'eco',
    },
  ];

  static const List<Map<String, dynamic>> odishaMilestones = [
    {
      'name': 'Dhauli Peace Stupa Trail',
      'distance': '5 km Completed',
      'status': 'Completed',
      'badge': '🕊️ Dhauli Champion',
      'isUnlocked': true,
    },
    {
      'name': 'Khandagiri & Udayagiri Caves Climb',
      'distance': '12 / 15 km',
      'status': 'In Progress',
      'badge': '🧗 Cave Conqueror',
      'isUnlocked': true,
    },
    {
      'name': 'Konark Sun Temple Ultra Run',
      'distance': 'Locked at Level 5',
      'status': 'Locked',
      'badge': '☀️ Sun Chariot',
      'isUnlocked': false,
    },
    {
      'name': 'Puri Golden Beach 10k Run',
      'distance': 'Locked at Level 6',
      'status': 'Locked',
      'badge': '🌊 Coastal Runner',
      'isUnlocked': false,
    },
  ];
}
