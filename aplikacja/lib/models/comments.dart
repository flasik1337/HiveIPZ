// Model dla komentarzy
class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      username: json['username'] ?? 'Nieznany użytkownik',
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}