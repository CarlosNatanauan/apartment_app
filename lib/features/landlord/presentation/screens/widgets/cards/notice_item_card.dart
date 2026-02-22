import 'package:apartment_app/features/landlord/data/models/notice_models.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NoticeItemCard extends StatelessWidget {
  final SpaceNotice notice;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const NoticeItemCard({
    super.key,
    required this.notice,
    this.onDelete,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notice.isExpired 
            ? AppTheme.textHint.withOpacity(0.05)
            : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notice.isExpired
              ? AppTheme.textHint.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji
              Text(
                notice.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              
              const SizedBox(width: 8),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: notice.isExpired
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        decoration: notice.isExpired
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          notice.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                          ),
                        ),
                        if (notice.hasExpiry) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notice.expiryText,
                            style: TextStyle(
                              fontSize: 11,
                              color: notice.isExpired
                                  ? AppTheme.errorColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Delete button
              if (showDeleteButton && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppTheme.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              notice.content,
              style: TextStyle(
                fontSize: 13,
                color: notice.isExpired
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}