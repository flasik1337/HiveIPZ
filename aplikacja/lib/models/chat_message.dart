class ChatMessage {
  final String id;
  final String userId;
  final String nickname;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      nickname: json['nickname'] ?? 'Nieznany użytkownik',
      text: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nickname': nickname,
      'content': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
