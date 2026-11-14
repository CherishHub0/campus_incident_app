import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident.dart';
import 'cloudinary_image_service.dart';

class IncidentService {
  IncidentService({CloudinaryImageService? imageService})
      : _imageService = imageService ?? CloudinaryImageService();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('incidents');
  final CloudinaryImageService _imageService;

  /// Live stream of all incidents, newest first (READ).
  Stream<List<Incident>> watchIncidents() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  /// CREATE – uploads the optional photo first, then writes the document.
  Future<void> create({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required String reporterId,
    required String reporterName,
    required bool isAnonymous,
    File? image,
  }) async {
    final doc = _col.doc();
    final uploadedImage =
        image == null ? null : await _imageService.upload(image);

    await doc.set({
      'title': title,
      'description': description,
      'category': category.name,
      'location': location,
      'imageUrl': uploadedImage?.secureUrl,
      'imagePublicId': uploadedImage?.publicId,
      'status': IncidentStatus.submitted.value,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': [
        {
          'status': IncidentStatus.submitted.value,
          'at': Timestamp.now(),
        }
      ],
    });
  }

  /// UPDATE – staff only (enforced by security rules as well as the UI).
  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String staffName,
    String? note,
  }) {
    return _col.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
      if (note != null && note.trim().isNotEmpty) 'staffNote': note.trim(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status.value,
          'at': Timestamp.now(),
          'by': staffName,
        }
      ]),
    });
  }

  /// DELETE – owner (while still "submitted") or staff.
  Future<void> delete(Incident incident) => _col.doc(incident.id).delete();
}
