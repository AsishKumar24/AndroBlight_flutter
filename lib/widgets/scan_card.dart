import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/scan_history_item.dart';

/// Scan Card Widget - Displays a single history item

class ScanCard extends StatelessWidget {
  final ScanHistoryItem item;
  final Responsive responsive;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ScanCard({
    super.key,
    required this.item,
    required this.responsive,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = responsive;
    final isMalware = item.isMalware;
    final resultColor = isMalware ? AppTheme.malwareRed : AppTheme.benignGreen;
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Dismissible(
      key: Key(item.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: r.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.malwareRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: r.adaptive(small: 22.0, medium: 24.0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(r.spacingSM),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: resultColor.withAlpha(50), width: 1),
            ),
            child: Row(
              children: [
                // Result indicator
                Container(
                  width: r.adaptive(small: 42.0, medium: 48.0),
                  height: r.adaptive(small: 42.0, medium: 48.0),
                  decoration: BoxDecoration(
                    color: resultColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMalware ? Icons.warning_rounded : Icons.check_circle,
                    color: resultColor,
                    size: r.adaptive(small: 22.0, medium: 26.0),
                  ),
                ),
                SizedBox(width: r.spacingSM),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identifier
                      Text(
                        item.displayName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: r.spacingXS),
                      // Metadata row
                      Row(
                        children: [
                          // Scan type badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.spacingXS + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isApkScan
                                  ? AppTheme.accentCyan.withAlpha(25)
                                  : AppTheme.accentBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isApkScan ? 'APK' : 'Play Store',
                              style: TextStyle(
                                color: item.isApkScan
                                    ? AppTheme.accentCyan
                                    : AppTheme.accentBlue,
                                fontSize: r.sp(9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: r.spacingXS),
                          // Date
                          Expanded(
                            child: Text(
                              dateFormat.format(item.timestamp),
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: r.sp(10),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: r.spacingSM),
                // Confidence + verdict-changed badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.confidencePercent,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: r.sp(10),
                      ),
                    ),
                    if (item.verdictChanged) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withAlpha(120),
                          ),
                        ),
                        child: Text(
                          '⚠ Changed',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: r.sp(9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
