import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/common.dart';
import '../widgets/summary_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inc = context.watch<IncidentProvider>();
    final mine = inc.mine(auth.uid);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Profile',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration(),
            child: Row(
              children: [
                UserAvatar(text: initials(auth.displayName), radius: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.displayName,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(auth.email ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: auth.isStaff
                        ? AppColors.amberBg
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.isStaff ? 'Staff' : 'Student',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: auth.isStaff
                          ? AppColors.amberFg
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.description_outlined,
                  value: mine.length,
                  label: 'Total Reports',
                  bg: AppColors.primaryLight,
                  fg: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  icon: Icons.schedule_rounded,
                  value: inc.count(mine, IncidentStatus.inProgress),
                  label: 'In Progress',
                  bg: AppColors.blueBg,
                  fg: AppColors.blueFg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: inc.count(mine, IncidentStatus.resolved),
                  label: 'Resolved',
                  bg: AppColors.greenBg,
                  fg: AppColors.greenFg,
                ),
              ),
            ],
          ),
          if (auth.isStaff) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.amberFg),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are signed in as campus staff. Open any report to '
                      'update its status.',
                      style: TextStyle(color: AppColors.amberFg, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.redFg,
              side: const BorderSide(color: AppColors.redFg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
