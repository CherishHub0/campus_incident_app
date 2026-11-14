import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/incident.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      IncidentStatus.submitted => (AppColors.amberBg, AppColors.amberFg),
      IncidentStatus.inProgress => (AppColors.primaryLight, AppColors.primaryDark),
      IncidentStatus.resolved => (AppColors.greenBg, AppColors.greenFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
