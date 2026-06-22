import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompatibilityBadge extends StatelessWidget {
  final int count;
  final bool isWarning;

  const CompatibilityBadge({
    super.key,
    required this.count,
    this.isWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isWarning ? AppTheme.error : AppTheme.warning).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            size: 16,
            color: isWarning ? AppTheme.error : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: isWarning ? AppTheme.error : AppTheme.warning,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
