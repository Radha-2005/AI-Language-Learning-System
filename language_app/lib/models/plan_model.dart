class PlanDay {
  final String id;
  final int dayNumber;
  final String scheduledDate;
  final String module;
  final String topic;
  final String contentType;
  final String status;
  final List<PracticeItem> items;

  PlanDay({
    required this.id,
    required this.dayNumber,
    required this.scheduledDate,
    required this.module,
    required this.topic,
    required this.contentType,
    required this.status,
    required this.items,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      id: json['id'] ?? '',
      dayNumber: json['day_number'] ?? 0,
      scheduledDate: json['scheduled_date'] ?? '',
      module: json['module'] ?? 'speech',
      topic: json['topic'] ?? '',
      contentType: json['content_type'] ?? 'word',
      status: json['status'] ?? 'pending',
      items: json['items'] != null
          ? List<PracticeItem>.from(
              (json['items'] as List).map((i) => PracticeItem.fromJson(i)))
          : [],
    );
  }

  bool get isDone => status == 'done';
  bool get isToday => status == 'pending' && items.isNotEmpty;

  String get topicDisplay => topic.replaceAll('_', ' ');
  String get contentTypeDisplay {
    switch (contentType) {
      case 'word':
        return 'Single words';
      case 'phrase':
        return 'Short phrases';
      case 'sentence':
        return 'Full sentences';
      case 'paragraph':
        return 'Paragraphs';
      default:
        return contentType;
    }
  }
}

class PracticeItem {
  final String text;
  final String transliteration;
  final String translation;
  final int difficulty;

  PracticeItem({
    required this.text,
    required this.transliteration,
    required this.translation,
    required this.difficulty,
  });

  factory PracticeItem.fromJson(Map<String, dynamic> json) {
    return PracticeItem(
      text: json['text'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
      difficulty: json['difficulty'] ?? 1,
    );
  }
}