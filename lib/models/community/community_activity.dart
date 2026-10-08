import 'package:flutter/material.dart';

class CommunityActivity {
  final String id;
  final String studentId;
  final String studentName;
  final String studentInitials;
  final int studentLevel;
  final String actionText;
  final String activityDetail;
  final DateTime timestamp;
  final String activityType;

  const CommunityActivity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentInitials,
    required this.studentLevel,
    required this.actionText,
    required this.activityDetail,
    required this.timestamp,
    required this.activityType,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData get icon {
    switch (activityType) {
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'challenge':
        return Icons.emoji_events_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'steps':
        return Icons.directions_walk_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  Color get iconColor {
    switch (activityType) {
      case 'workout':
        return const Color(0xFF22C55E); // Green
      case 'streak':
        return const Color(0xFFF97316); // Orange
      case 'challenge':
        return const Color(0xFFEAB308); // Yellow
      case 'meal':
        return const Color(0xFF06B6D4); // Cyan
      case 'steps':
        return const Color(0xFFA855F7); // Purple
      default:
        return const Color(0xFF22C55E);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentInitials': studentInitials,
    'studentLevel': studentLevel,
    'actionText': actionText,
    'activityDetail': activityDetail,
    'timestamp': timestamp.toIso8601String(),
    'activityType': activityType,
  };

  factory CommunityActivity.fromJson(Map<String, dynamic> json) =>
      CommunityActivity(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        studentInitials: json['studentInitials'] as String,
        studentLevel: (json['studentLevel'] as num).toInt(),
        actionText: json['actionText'] as String,
        activityDetail: json['activityDetail'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        activityType: json['activityType'] as String,
      );
}
