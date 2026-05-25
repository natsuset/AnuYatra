import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final ServiceTask task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: task.priority.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with priority indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: task.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: task.priority.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.isCompleted
                    ? AppTheme.statusGreen
                    : AppTheme.tertiaryText(context),
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Task title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: task.isCompleted
                  ? AppTheme.tertiaryText(context)
                  : AppTheme.primaryText(context),
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // Task description
          Text(
            task.description,
            style: TextStyle(
              fontSize: 9,
              color: task.isCompleted
                  ? AppTheme.tertiaryText(context)
                  : AppTheme.secondaryText(context),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Resources or due date
          if (task.resources.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attachment,
                  size: 12,
                  color: AppTheme.tertiaryText(context),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${task.resources.length} resource${task.resources.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.tertiaryText(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (task.dueDate != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 12, color: AppTheme.tertiaryText(context)),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    'Due: ${task.dueDate!.day}/${task.dueDate!.month}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.tertiaryText(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
