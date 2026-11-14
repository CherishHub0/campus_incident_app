import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../services/cloudinary_image_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _room = TextEditingController();
  IncidentCategory _category = IncidentCategory.facilities;
  String? _location;
  File? _image;
  bool _anonymous = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (x != null) setState(() => _image = File(x.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the camera/gallery.')),
      );
    }
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final inc = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final room = _room.text.trim();
    final location = room.isEmpty ? _location! : '$_location — $room';
    try {
      await inc.submit(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        location: location,
        reporterId: auth.uid!,
        reporterName: auth.displayName,
        isAnonymous: _anonymous,
        image: _image,
      );
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you!')),
      );
    } on CloudinaryUploadException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not submit the report. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<IncidentProvider>().submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _label('Select a category'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IncidentCategory.values.map(_categoryTile).toList(),
              ),
              const SizedBox(height: 20),
              _label('Title'),
              TextFormField(
                controller: _title,
                maxLength: 80,
                decoration:
                    const InputDecoration(hintText: 'Briefly describe the issue…'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Enter a short title (min 3 characters)'
                    : null,
              ),
              const SizedBox(height: 8),
              _label('Description'),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Provide more details about the issue…\ne.g. what happened, when, impact, etc.',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please add a bit more detail (min 10 characters)'
                    : null,
              ),
              const SizedBox(height: 8),
              _label('Location'),
              DropdownButtonFormField<String>(
                initialValue: _location,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select a location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: campusLocations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _location = v),
                validator: (v) => v == null ? 'Select where the issue is' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _room,
                decoration: const InputDecoration(
                    hintText: 'Room / floor (optional), e.g. Room 204'),
              ),
              const SizedBox(height: 20),
              _label('Add a photo (optional)'),
              _photoBox(),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text('Report anonymously',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Your name is hidden from other students and staff.',
                    style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(IncidentCategory c) {
    final selected = c == _category;
    return GestureDetector(
      onTap: () => setState(() => _category = c),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(c.icon,
                color: selected ? Colors.white : AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(c.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primaryDark,
                )),
          ],
        ),
      ),
    );
  }

  Widget _photoBox() {
    if (_image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_image!,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _image = null),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _photoSheet,
      child: Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 28),
            SizedBox(height: 4),
            Text('Tap to add photos',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
      );
}
