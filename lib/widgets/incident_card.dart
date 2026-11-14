import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import '../screens/incident_details_screen.dart';
import 'status_badge.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncidentDetailsScreen(incidentId: incident.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: cardDecoration(),
        child: Row(
          children: [
            _Thumb(incident),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _meta(Icons.location_on_outlined, incident.location),
                  const SizedBox(height: 2),
                  _meta(Icons.schedule_rounded, timeAgo(incident.createdAt)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(incident.status),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    ],
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.incident);
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 56,
      height: 56,
      color: AppColors.primaryLight,
      child: Icon(incident.category.icon, color: AppColors.primary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: incident.imageUrl == null
          ? fallback
          : Image.network(
              incident.imageUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
