class JapaneseText {
  final String content;
  final String translation;
  final String jlptLevel;
  final String topic;

  JapaneseText({
    required this.content,
    required this.translation,
    required this.jlptLevel,
    required this.topic,
  });

  factory JapaneseText.fromJson(Map<String, dynamic> json) {
    return JapaneseText(
      content: json['content'] ?? '',
      translation: json['translation'] ?? '',
      jlptLevel: json['jlptLevel'] ?? 'N5',
      topic: json['topic'] ?? 'Random',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'translation': translation,
      'jlptLevel': jlptLevel,
      'topic': topic,
    };
  }
}