import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum IncidentCategory {
  facilities,
  water,
  electricity,
  safety,
  sanitation;

  String get label => switch (this) {
        IncidentCategory.facilities => 'Facilities',
        IncidentCategory.water => 'Water',
        IncidentCategory.electricity => 'Electricity',
        IncidentCategory.safety => 'Safety',
        IncidentCategory.sanitation => 'Sanitation',
      };

  IconData get icon => switch (this) {
        IncidentCategory.facilities => Icons.apartment_rounded,
        IncidentCategory.water => Icons.water_drop_outlined,
        IncidentCategory.electricity => Icons.bolt_rounded,
        IncidentCategory.safety => Icons.shield_outlined,
        IncidentCategory.sanitation => Icons.delete_outline_rounded,
      };

  static IncidentCategory parse(String? v) => IncidentCategory.values
      .firstWhere((e) => e.name == v, orElse: () => IncidentCategory.facilities);
}

enum IncidentStatus {
  submitted('submitted', 'Submitted'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved');

  const IncidentStatus(this.value, this.label);
  final String value;
  final String label;

  static IncidentStatus parse(String? v) => IncidentStatus.values
      .firstWhere((e) => e.value == v, orElse: () => IncidentStatus.submitted);
}

DateTime _ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class StatusEntry {
  final IncidentStatus status;
  final DateTime at;
  final String? by;

  const StatusEntry({required this.status, required this.at, this.by});

  factory StatusEntry.fromMap(Map<String, dynamic> m) => StatusEntry(
        status: IncidentStatus.parse(m['status'] as String?),
        at: _ts(m['at']),
        by: m['by'] as String?,
      );
}

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final String? imageUrl;
  final String? imagePublicId;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusEntry> history;
  final String? staffNote;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.imageUrl,
    this.imagePublicId,
    this.staffNote,
  });

  /// Name shown in the UI (respects anonymous reporting).
  String get displayReporter => isAnonymous ? 'Anonymous' : reporterName;

  DateTime? dateFor(IncidentStatus s) {
    for (final e in history) {
      if (e.status == s) return e.at;
    }
    return null;
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawHistory = (d['statusHistory'] as List?) ?? const [];
    return Incident(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      category: IncidentCategory.parse(d['category'] as String?),
      location: (d['location'] as String?) ?? '',
      imageUrl: d['imageUrl'] as String?,
      imagePublicId: d['imagePublicId'] as String?,
      status: IncidentStatus.parse(d['status'] as String?),
      reporterId: (d['reporterId'] as String?) ?? '',
      reporterName: (d['reporterName'] as String?) ?? 'Student',
      isAnonymous: (d['isAnonymous'] as bool?) ?? false,
      createdAt: _ts(d['createdAt']),
      updatedAt: _ts(d['updatedAt']),
      history: rawHistory
          .map((e) => StatusEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      staffNote: d['staffNote'] as String?,
    );
  }
}
