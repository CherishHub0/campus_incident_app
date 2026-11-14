import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._service);

  final IncidentService _service;
  StreamSubscription<List<Incident>>? _sub;
  String? _uid;

  List<Incident> _all = [];
  bool loading = false;
  bool submitting = false;
  String? error;

  // Filters
  String query = '';
  IncidentCategory? categoryFilter;
  IncidentStatus? statusFilter;
  bool mineOnly = false;

  List<Incident> get all => _all;

  /// Starts / stops the Firestore listener when the signed-in user changes.
  /// Called from ChangeNotifierProxyProvider.update.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _all = [];
    error = null;
    mineOnly = false;
    query = '';
    categoryFilter = null;
    statusFilter = null;
    if (uid == null) {
      loading = false;
      return;
    }
    loading = true;
    _listenToReports();
  }

  void retry() {
    if (_uid == null) return;
    _sub?.cancel();
    _sub = null;
    loading = true;
    error = null;
    notifyListeners();
    _listenToReports();
  }

  void _listenToReports() {
    _sub = _service.watchIncidents().listen(
      (list) {
        _all = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (Object caught, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Failed to load Firestore reports: $caught\n$stackTrace');
        }
        loading = false;
        error = _loadErrorMessage(caught);
        notifyListeners();
      },
    );
  }

  String _loadErrorMessage(Object caught) {
    if (caught is FirebaseException) {
      if (caught.code == 'not-found' ||
          caught.message?.contains('database (default) does not exist') ==
              true) {
        return 'Cloud Firestore has not been created for this Firebase project. '
            'Create the default Firestore database in Firebase Console.';
      }
      return switch (caught.code) {
        'permission-denied' =>
          'Firestore denied access to reports. Confirm your email is verified '
              'and publish the current Firestore rules in Firebase Console.',
        'unauthenticated' =>
          'Your session has expired. Sign out and sign in again.',
        'unavailable' || 'deadline-exceeded' => 'Firestore is temporarily unavailable. Check your connection and try again.',
        'failed-precondition' =>
          'Firestore could not run the reports query. Check the Firebase error '
              'details for a required index or configuration issue.',
        _ =>
          'Could not load reports (Firestore error: ${caught.code}). '
              'Try again, and check the app log if the problem continues.',
      };
    }

    return 'Could not read the reports. One or more incident documents may '
        'have an unexpected format.';
  }

  List<Incident> mine(String? uid) =>
      _all.where((i) => i.reporterId == uid).toList();

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<Incident> get filtered {
    final q = query.trim().toLowerCase();
    return _all.where((i) {
      if (mineOnly && i.reporterId != _uid) return false;
      if (categoryFilter != null && i.category != categoryFilter) return false;
      if (statusFilter != null && i.status != statusFilter) return false;
      if (q.isNotEmpty &&
          !(i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.location.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  int count(List<Incident> list, IncidentStatus s) =>
      list.where((i) => i.status == s).length;

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(IncidentCategory? c) {
    categoryFilter = c;
    notifyListeners();
  }

  void setStatus(IncidentStatus? s) {
    statusFilter = s;
    notifyListeners();
  }

  void setMineOnly(bool v) {
    mineOnly = v;
    notifyListeners();
  }

  Future<void> submit({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required String reporterId,
    required String reporterName,
    required bool isAnonymous,
    File? image,
  }) async {
    submitting = true;
    notifyListeners();
    try {
      await _service.create(
        title: title,
        description: description,
        category: category,
        location: location,
        reporterId: reporterId,
        reporterName: reporterName,
        isAnonymous: isAnonymous,
        image: image,
      );
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String staffName,
    String? note,
  }) => _service.updateStatus(
    id: id,
    status: status,
    staffName: staffName,
    note: note,
  );

  Future<void> delete(Incident incident) => _service.delete(incident);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
