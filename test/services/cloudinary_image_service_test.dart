import 'dart:convert';
import 'dart:io';

import 'package:campus_incident_app/services/cloudinary_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tempDirectory;
  late File image;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp();
    image = File(
      '${tempDirectory.path}${Platform.pathSeparator}incident.jpg',
    );
    await image.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('uploads an image and returns its secure URL and public ID', () async {
    final client = MockClient((request) async {
      expect(request, isA<http.Request>());
      expect(request.url.host, 'api.cloudinary.com');
      expect(request.method, 'POST');
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('name="upload_preset"'));
      expect(request.body, contains('unsigned-test-preset'));
      expect(request.body, contains('name="file"'));

      return http.Response(
        jsonEncode({
          'secure_url': 'https://res.cloudinary.com/demo/image/upload/test.jpg',
          'public_id': 'campus_incidents/test',
        }),
        200,
      );
    });
    final service = CloudinaryImageService(
      cloudName: 'demo',
      uploadPreset: 'unsigned-test-preset',
      client: client,
    );

    final result = await service.upload(image);

    expect(
      result.secureUrl,
      'https://res.cloudinary.com/demo/image/upload/test.jpg',
    );
    expect(result.publicId, 'campus_incidents/test');
    client.close();
  });

  test('reports when Cloudinary configuration is missing', () async {
    final client = MockClient((_) async => http.Response('', 500));
    final service = CloudinaryImageService(
      cloudName: '',
      uploadPreset: '',
      client: client,
    );

    await expectLater(
      service.upload(image),
      throwsA(isA<CloudinaryUploadException>()),
    );
    client.close();
  });

  test('surfaces Cloudinary upload errors', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'Upload preset is invalid'},
        }),
        400,
      ),
    );
    final service = CloudinaryImageService(
      cloudName: 'demo',
      uploadPreset: 'bad-preset',
      client: client,
    );

    await expectLater(
      service.upload(image),
      throwsA(
        isA<CloudinaryUploadException>().having(
          (error) => error.message,
          'message',
          'Upload preset is invalid',
        ),
      ),
    );
    client.close();
  });
}
