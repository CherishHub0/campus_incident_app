import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryImageService {
  CloudinaryImageService({
    String? cloudName,
    String? uploadPreset,
    this._client,
  })  : _cloudName = cloudName ?? CloudinaryConfig.cloudName,
        _uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset;

  static const maxFileSizeBytes = 5 * 1024 * 1024;
  static const _timeout = Duration(seconds: 60);

  final String _cloudName;
  final String _uploadPreset;
  final http.Client? _client;

  Future<CloudinaryUploadResult> upload(File image) async {
    if (_cloudName.trim().isEmpty || _uploadPreset.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET in your run configuration.',
      );
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(_cloudName)) {
      throw const CloudinaryUploadException(
        'The Cloudinary cloud name is invalid.',
      );
    }
    if (await image.length() > maxFileSizeBytes) {
      throw const CloudinaryUploadException(
        'Choose an image smaller than 5 MB.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.https(
        'api.cloudinary.com',
        '/v1_1/$_cloudName/image/upload',
      ),
    )
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final client = _client ?? http.Client();
    try {
      final response = await http.Response.fromStream(
        await client.send(request).timeout(_timeout),
      ).timeout(_timeout);
      final payload = _decodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = payload?['error'];
        final message =
            error is Map<String, dynamic> ? error['message'] as String? : null;
        throw CloudinaryUploadException(
          message ?? 'Cloudinary upload failed (${response.statusCode}).',
        );
      }

      final secureUrl = payload?['secure_url'];
      final publicId = payload?['public_id'];
      final parsedUrl =
          secureUrl is String ? Uri.tryParse(secureUrl) : null;
      if (parsedUrl == null ||
          parsedUrl.scheme != 'https' ||
          publicId is! String ||
          publicId.isEmpty) {
        throw const CloudinaryUploadException(
          'Cloudinary returned an incomplete image response.',
        );
      }

      return CloudinaryUploadResult(
        secureUrl: secureUrl,
        publicId: publicId,
      );
    } on TimeoutException {
      throw const CloudinaryUploadException(
        'Image upload timed out. Check your connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw CloudinaryUploadException(
        'Could not reach Cloudinary: ${error.message}',
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Map<String, dynamic>? _decodePayload(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
