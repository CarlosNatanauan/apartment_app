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
    final isExpired = notice.isExpired;
    final accentColor = isExpired ? AppTheme.textSecondary : AppTheme.landlordColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpired
            ? AppTheme.textHint.withValues(alpha: 0.05)
            : AppTheme.landlordColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpired
              ? AppTheme.textHint.withValues(alpha: 0.15)
              : AppTheme.landlordColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  notice.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isExpired
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            decoration:
                                isExpired ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (showDeleteButton && onDelete != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.textHint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notice.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isExpired
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Meta row: timeAgo + expiry pill
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
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isExpired
                                    ? AppTheme.errorColor
                                    : AppTheme.warningColor)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notice.expiryText,
                            style: TextStyle(
                              fontSize: 10,
                              color: isExpired
                                  ? AppTheme.errorColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
