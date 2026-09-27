class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;
  final String authorId;
  final String authorName;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
    };
  }

  factory NewsModel.fromMap(Map<String, dynamic> map, String docId) {
    return NewsModel(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      category: map['category'] ?? 'عام',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
    );
  }
}