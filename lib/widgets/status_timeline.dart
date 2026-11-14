import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';

/// Submitted → In Progress → Resolved, with timestamps from statusHistory.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final steps = IncidentStatus.values;
    final current = steps.indexOf(incident.status);
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i <= current;
      final date = incident.dateFor(steps[i]);
      children.add(SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : AppColors.border,
              ),
              child: Icon(
                done ? Icons.check_rounded : null,
                size: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[i].label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                color: done ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date == null ? '—' : '${formatDate(date)}\n${formatTime(date)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ));
      if (i < steps.length - 1) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Container(
              height: 2,
              color: i < current ? AppColors.primary : AppColors.border,
            ),
          ),
        ));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
