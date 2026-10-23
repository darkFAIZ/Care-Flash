import 'dart:convert';

import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';

/// Edits the signed-in caregiver's display name and profile photo. (Phase 5)
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  static const String route = '/profile/edit';

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _avatarDataUrl;
  bool _busy = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _avatarDataUrl =
          'data:${picked.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    final platform = ref.read(platformProvider);
    await platform.updateProfile(name: _name.text.trim());
    await platform.updateAvatar(avatarDataUrl: _avatarDataUrl);
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      const SnackBar(content: AppText('Profile updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = ref.watch(caregiverStateProvider).value;

    if (caregiver == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_prefilled) {
      _name.text = caregiver.name;
      _avatarDataUrl = caregiver.avatarDataUrl;
      _prefilled = true;
    }

    return Scaffold(
      appBar: AppBar(title: const AppText('Edit profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              Center(
                child: UserAvatar(
                  name: _name.text.isEmpty ? caregiver.name : _name.text,
                  avatarDataUrl: _avatarDataUrl,
                  radius: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppButton(
                    label: 'Change photo',
                    variant: AppButtonVariant.secondary,
                    icon: Icons.photo_camera_outlined,
                    expand: false,
                    onPressed: _busy ? null : _pickPhoto,
                  ),
                  if (_avatarDataUrl != null)
                    AppButton(
                      label: 'Remove photo',
                      variant: AppButtonVariant.ghost,
                      expand: false,
                      onPressed: _busy
                          ? null
                          : () => setState(() => _avatarDataUrl = null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _name,
                label: 'Full name',
                required: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter your name.'
                    : null,
                // Rebuild so the avatar initials preview follows typing.
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _busy ? null : _save(),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Your name and photo are shown to care seekers you are '
                'matched with.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Save changes',
                loading: _busy,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
