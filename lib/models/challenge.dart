class Challenge {
  final String id;
  final String title;
  final String description;
  final int rewardXp;
  final int progress;
  final int target;
  final String unit;
  final bool isCompleted;
  final String category;
  final String timeLeft;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    required this.progress,
    required this.target,
    required this.unit,
    this.isCompleted = false,
    required this.category,
    required this.timeLeft,
  });

  double get progressRatio => (progress / target).clamp(0.0, 1.0);

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardXp,
    int? progress,
    int? target,
    String? unit,
    bool? isCompleted,
    String? category,
    String? timeLeft,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardXp: rewardXp ?? this.rewardXp,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'rewardXp': rewardXp,
    'progress': progress,
    'target': target,
    'unit': unit,
    'isCompleted': isCompleted,
    'category': category,
    'timeLeft': timeLeft,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    rewardXp: json['rewardXp'] as int,
    progress: json['progress'] as int,
    target: json['target'] as int,
    unit: json['unit'] as String,
    isCompleted: (json['isCompleted'] as bool?) ?? false,
    category: json['category'] as String,
    timeLeft: json['timeLeft'] as String,
  );
}
