class WordScore {
  final String text;
  final double score;
  final String heard;
  final String feedback;
  final bool passed;

  WordScore({
    required this.text,
    required this.score,
    required this.heard,
    required this.feedback,
    required this.passed,
  });

  factory WordScore.fromJson(Map<String, dynamic> json) {
    return WordScore(
      text: json['target'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      heard: json['heard'] ?? '',
      feedback: json['feedback'] ?? '',
      passed: json['passed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'score': score,
      };
}

class SessionResult {
  final double sessionScore;
  final int xpEarned;
  final List<String> weakAreas;
  final LevelUpdate levelUpdate;
  final String completedDate;
  final String message;

  SessionResult({
    required this.sessionScore,
    required this.xpEarned,
    required this.weakAreas,
    required this.levelUpdate,
    required this.completedDate,
    required this.message,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      sessionScore: (json['session_score'] as num?)?.toDouble() ?? 0.0,
      xpEarned: json['xp_earned'] ?? 0,
      weakAreas: List<String>.from(json['weak_areas'] ?? []),
      levelUpdate: LevelUpdate.fromJson(json['level_update'] ?? {}),
      completedDate: json['completed_date'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class LevelUpdate {
  final bool changed;
  final String direction;
  final String oldLevel;
  final String newLevel;
  final double avg;
  final String message;

  LevelUpdate({
    required this.changed,
    required this.direction,
    required this.oldLevel,
    required this.newLevel,
    required this.avg,
    required this.message,
  });

  factory LevelUpdate.fromJson(Map<String, dynamic> json) {
    return LevelUpdate(
      changed: json['changed'] ?? false,
      direction: json['direction'] ?? '',
      oldLevel: json['old'] ?? '',
      newLevel: json['new'] ?? '',
      avg: (json['avg'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
    );
  }
}

class DashboardData {
  final String userName;
  final String language;
  final String level;
  final int streak;
  final int totalXp;
  final List<PlanDaySummary> weekPlan;
  final List<RecentScore> recentScores;

  DashboardData({
    required this.userName,
    required this.language,
    required this.level,
    required this.streak,
    required this.totalXp,
    required this.weekPlan,
    required this.recentScores,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userName: json['user_name'] ?? 'Learner',
      language: json['language'] ?? 'hindi',
      level: json['level'] ?? 'beginner',
      streak: json['streak'] ?? 0,
      totalXp: json['total_xp'] ?? 0,
      weekPlan: json['week_plan'] != null
          ? List<PlanDaySummary>.from(
              (json['week_plan'] as List).map((d) => PlanDaySummary.fromJson(d)))
          : [],
      recentScores: json['recent_scores'] != null
          ? List<RecentScore>.from(
              (json['recent_scores'] as List).map((s) => RecentScore.fromJson(s)))
          : [],
    );
  }
}

class PlanDaySummary {
  final int dayNumber;
  final String scheduledDate;
  final String module;
  final String topic;
  final String contentType;
  final String status;

  PlanDaySummary({
    required this.dayNumber,
    required this.scheduledDate,
    required this.module,
    required this.topic,
    required this.contentType,
    required this.status,
  });

  factory PlanDaySummary.fromJson(Map<String, dynamic> json) {
    return PlanDaySummary(
      dayNumber: json['day_number'] ?? json['day'] ?? 0,
      scheduledDate: json['scheduled_date'] ?? '',
      module: json['module'] ?? 'speech',
      topic: json['topic'] ?? '',
      contentType: json['content_type'] ?? 'word',
      status: json['status'] ?? 'pending',
    );
  }

  bool get isDone => status == 'done';
  String get topicDisplay => topic.replaceAll('_', ' ');
}

class RecentScore {
  final String date;
  final double score;
  final String module;

  RecentScore({
    required this.date,
    required this.score,
    required this.module,
  });

  factory RecentScore.fromJson(Map<String, dynamic> json) {
    return RecentScore(
      date: json['date'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      module: json['module'] ?? 'speech',
    );
  }
}