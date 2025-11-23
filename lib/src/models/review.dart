class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.author,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String author;
  final String comment;
  final double rating;
  final DateTime createdAt;

  String get dateLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else {
      return 'Today';
    }
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      // Handle join with profiles table for author name
      author: json['profiles'] != null ? json['profiles']['name'] as String : 'Anonymous',
      comment: json['comment'] as String? ?? '',
      rating: (json['rating'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

