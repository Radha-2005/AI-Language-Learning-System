class UserModel {
  final String id;
  final String name;
  final String language;
  final String goal;
  final String level;

  UserModel({
    required this.id,
    required this.name,
    required this.language,
    required this.goal,
    required this.level,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? '',
      name: json['name'] ?? '',
      language: json['language'] ?? 'hindi',
      goal: json['goal'] ?? 'conversational',
      level: json['level'] ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'name': name,
        'language': language,
        'goal': goal,
        'level': level,
      };
}