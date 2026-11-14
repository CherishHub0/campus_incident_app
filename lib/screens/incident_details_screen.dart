import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/status_timeline.dart';

class IncidentDetailsScreen extends StatefulWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  IncidentStatus? _newStatus;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(Incident incident) async {
    final status = _newStatus ?? incident.status;
    final auth = context.read<AuthProvider>();
    final inc = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await inc.updateStatus(
        id: incident.id,
        status: status,
        staffName: auth.displayName,
        note: _note.text,
      );
      _note.clear();
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Update failed. You may not have permission.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Incident incident) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final inc = context.read<IncidentProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.redFg))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await inc.delete(incident);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not delete the report.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incident = context.watch<IncidentProvider>().byId(widget.incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: Text('This report no longer exists.')),
      );
    }

    final canDelete = auth.isStaff ||
        (incident.reporterId == auth.uid &&
            incident.status == IncidentStatus.submitted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canDelete)
            PopupMenuButton<String>(
              onSelected: (_) => _delete(incident),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete report')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(incident.category.icon,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(incident.title,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          StatusBadge(incident.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _info(Icons.category_outlined, incident.category.label),
                _info(Icons.location_on_outlined, incident.location),
                _info(Icons.schedule_rounded,
                    'Submitted on ${formatDateTime(incident.createdAt)}'),
                _info(Icons.person_outline_rounded,
                    'Reported by ${incident.displayReporter}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Timeline',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 14),
                StatusTimeline(incident: incident),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Text(incident.description,
                    style: const TextStyle(
                        color: AppColors.textMuted, height: 1.45)),
                if (incident.staffNote != null) ...[
                  const SizedBox(height: 14),
                  const Text('Staff note',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text(incident.staffNote!,
                      style: const TextStyle(
                          color: AppColors.primaryDark, height: 1.4)),
                ],
              ],
            ),
          ),
          if (incident.imageUrl != null) ...[
            const SizedBox(height: 16),
            const Text('Attached Photo',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                incident.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Text('Photo unavailable'),
                ),
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
          ],
          if (auth.isStaff) ...[
            const SizedBox(height: 20),
            _staffPanel(incident),
          ],
        ],
      ),
    );
  }

  Widget _staffPanel(Incident incident) {
    final selected = _newStatus ?? incident.status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(color: AppColors.primaryLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.primaryDark, size: 20),
              SizedBox(width: 8),
              Text('Staff: update status',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<IncidentStatus>(
              showSelectedIcon: false,
              segments: IncidentStatus.values
                  .map((s) => ButtonSegment(
                      value: s,
                      label: Text(s.label, style: const TextStyle(fontSize: 11.5))))
                  .toList(),
              selected: {selected},
              onSelectionChanged: (s) => setState(() => _newStatus = s.first),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Add a note for the student (optional)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving || selected == incident.status && _note.text.trim().isEmpty
                ? null
                : () => _updateStatus(incident),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Update status'),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
}
