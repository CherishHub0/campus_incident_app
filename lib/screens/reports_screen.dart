import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';
import '../widgets/common.dart';
import '../widgets/incident_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentProvider>();
    final list = inc.filtered;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: inc.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search by title, description or location',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('All reports')),
                  ButtonSegment(value: true, label: Text('My reports')),
                ],
                selected: {inc.mineOnly},
                onSelectionChanged: (s) => inc.setMineOnly(s.first),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _chipRow<IncidentStatus>(
            values: IncidentStatus.values,
            selected: inc.statusFilter,
            label: (s) => s.label,
            onSelected: inc.setStatus,
          ),
          const SizedBox(height: 8),
          _chipRow<IncidentCategory>(
            values: IncidentCategory.values,
            selected: inc.categoryFilter,
            label: (c) => c.label,
            onSelected: inc.setCategory,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: inc.loading
                ? const Center(child: CircularProgressIndicator())
                : inc.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.textMuted,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            inc.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: inc.retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : list.isEmpty
                ? const SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'No reports match your filters.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => IncidentCard(incident: list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    required void Function(T?) onSelected,
  }) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip('All', selected == null, () => onSelected(null)),
          ...values.map(
            (v) => _chip(label(v), selected == v, () => onSelected(v)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    ),
  );
}
