import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/common.dart';
import '../widgets/incident_card.dart';
import '../widgets/summary_tile.dart';
import '../core/utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onReport, required this.onSeeAll});

  final VoidCallback onReport;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inc = context.watch<IncidentProvider>();
    final scope = auth.isStaff ? inc.all : inc.mine(auth.uid);
    final recent = inc.all.take(3).toList();
    final firstName = auth.displayName.split(' ').first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Help make our campus safer.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Text(
                      'Report issues and track their resolution.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textDark,
              ),
              const SizedBox(width: 12),
              UserAvatar(text: initials(auth.displayName)),
            ],
          ),
          const SizedBox(height: 20),
          _HeroCard(onReport: onReport),
          const SizedBox(height: 24),
          _sectionHeader('Report Summary', null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.description_outlined,
                  value: scope.length,
                  label: auth.isStaff ? 'All Reports' : 'My Reports',
                  bg: AppColors.primaryLight,
                  fg: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.schedule_rounded,
                  value: inc.count(scope, IncidentStatus.inProgress),
                  label: 'In Progress',
                  bg: AppColors.blueBg,
                  fg: AppColors.blueFg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: inc.count(scope, IncidentStatus.resolved),
                  label: 'Resolved',
                  bg: AppColors.greenBg,
                  fg: AppColors.greenFg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.priority_high_rounded,
                  value: inc.count(scope, IncidentStatus.submitted),
                  label: 'Submitted',
                  bg: AppColors.redBg,
                  fg: AppColors.redFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionHeader('Recent Reports', onSeeAll),
          const SizedBox(height: 12),
          if (inc.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (inc.error != null)
            Column(
              children: [
                EmptyState(
                  icon: Icons.error_outline_rounded,
                  message: inc.error!,
                ),
                TextButton.icon(
                  onPressed: inc.retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            )
          else if (recent.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No reports yet.\nTap "Report an Issue" to submit the first one.',
            )
          else
            ...recent.map((i) => IncidentCard(incident: i)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback? onSeeAll) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -4,
            child: Icon(
              Icons.apartment_rounded,
              size: 96,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'See an issue\non campus?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Report it and help improve\nour learning environment.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onReport,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_rounded, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Report an Issue',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
