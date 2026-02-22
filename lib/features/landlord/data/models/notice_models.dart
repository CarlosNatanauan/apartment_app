// Space Notice Model
class SpaceNotice {
  final String noticeId;
  final String title;
  final String content;
  final DateTime? expiresAt;
  final DateTime createdAt;

  SpaceNotice({
    required this.noticeId,
    required this.title,
    required this.content,
    this.expiresAt,
    required this.createdAt,
  });

  factory SpaceNotice.fromJson(Map<String, dynamic> json) {
    return SpaceNotice(
      noticeId: json['noticeId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noticeId': noticeId,
      'title': title,
      'content': content,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Computed properties
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  bool get hasExpiry => expiresAt != null;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  String get expiryText {
    if (expiresAt == null) return 'No expiry';
    
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);

    if (difference.isNegative) return 'Expired';

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Expires in $years ${years == 1 ? 'year' : 'years'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Expires in $months ${months == 1 ? 'month' : 'months'}';
    } else if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Expires soon';
    }
  }

  // Get emoji based on content keywords (optional, for visual appeal)
  String get emoji {
    final lowerTitle = title.toLowerCase();
    final lowerContent = content.toLowerCase();
    
    if (lowerTitle.contains('water') || lowerContent.contains('water')) return '💧';
    if (lowerTitle.contains('holiday') || lowerContent.contains('holiday')) return '🎉';
    if (lowerTitle.contains('maintenance') || lowerContent.contains('repair')) return '🔧';
    if (lowerTitle.contains('reminder') || lowerContent.contains('reminder')) return '⏰';
    if (lowerTitle.contains('important') || lowerContent.contains('urgent')) return '⚠️';
    if (lowerTitle.contains('parking')) return '🚗';
    if (lowerTitle.contains('rent') || lowerContent.contains('payment')) return '💰';
    if (lowerTitle.contains('welcome')) return '👋';
    
    return '📢'; // Default announcement emoji
  }
}