import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/common/widgets/molecules/photo_manager_widget.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:testing_flutter/models/candidate_profile.dart';

/// Form for brokers to create or edit a candidate profile.
class ProfileCreateEditScreen extends ConsumerStatefulWidget {
  const ProfileCreateEditScreen({super.key});

  @override
  ConsumerState<ProfileCreateEditScreen> createState() =>
      _ProfileCreateEditScreenState();
}

class _ProfileCreateEditScreenState
    extends ConsumerState<ProfileCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _educationController = TextEditingController();
  final _cityController = TextEditingController();
  final _heightController = TextEditingController();
  final _communityController = TextEditingController();
  final _religionController = TextEditingController();
  final _casteController = TextEditingController();
  final _motherTongueController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _familyBgController = TextEditingController();
  final _fatherOccController = TextEditingController();
  final _motherOccController = TextEditingController();
  final _siblingsController = TextEditingController();
  final _interestsController = TextEditingController();

  Gender _gender = Gender.bride;
  bool _isSaving = false;
  List<String> _photos = [];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    _cityController.dispose();
    _heightController.dispose();
    _communityController.dispose();
    _religionController.dispose();
    _casteController.dispose();
    _motherTongueController.dispose();
    _aboutMeController.dispose();
    _familyBgController.dispose();
    _fatherOccController.dispose();
    _motherOccController.dispose();
    _siblingsController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profileRepo = ref.read(profileRepositoryProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final now = DateTime.now();
    final interests = _interestsController.text.trim().isNotEmpty
        ? _interestsController.text.split(',').map((s) => s.trim()).toList()
        : <String>[];

    final profile = CandidateProfile(
      id: const Uuid().v4(),
      createdByUserId: authState.user.uid,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 25,
      gender: _gender,
      profession: _professionController.text.trim(),
      education: _educationController.text.trim(),
      city: _cityController.text.trim(),
      height: _heightController.text.trim(),
      community: _communityController.text.trim(),
      religion: _religionController.text.trim(),
      caste: _casteController.text.trim(),
      motherTongue: _motherTongueController.text.trim(),
      aboutMe: _aboutMeController.text.trim(),
      familyBackground: _familyBgController.text.trim(),
      fatherOccupation: _fatherOccController.text.trim(),
      motherOccupation: _motherOccController.text.trim(),
      siblings: _siblingsController.text.trim(),
      interests: interests,
      photos: _photos,
      brokerIds: [authState.user.uid],
      createdAt: now,
      updatedAt: now,
    );

    await profileRepo.saveCandidateProfile(profile);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile for ${profile.name} created!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.sacredSaffron,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.allMd,
          children: [
            // Gender selector
            Text(
              'Gender',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapH8,
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.bride, label: Text('Bride')),
                ButtonSegment(value: Gender.groom, label: Text('Groom')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    AppColors.sacredSaffron.withValues(alpha: 0.15),
                selectedForegroundColor: AppColors.sacredSaffron,
              ),
            ),
            const SizedBox(height: 20),

            // Basic Info
            _sectionLabel('Basic Information'),
            AppSpacing.gapH12,
            _field(_nameController, 'Full Name', icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            _fieldRow(
              _field(_ageController, 'Age', icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              _field(_heightController, 'Height', icon: Icons.height,
                  hint: "e.g., 5'6\""),
            ),
            _field(_professionController, 'Profession',
                icon: Icons.work_outline),
            _field(_educationController, 'Education',
                icon: Icons.school_outlined),
            _field(_cityController, 'City', icon: Icons.location_on_outlined),
            const SizedBox(height: 20),

            // Community
            _sectionLabel('Community & Background'),
            AppSpacing.gapH12,
            _fieldRow(
              _field(_religionController, 'Religion',
                  icon: Icons.temple_hindu_outlined),
              _field(_casteController, 'Caste',
                  icon: Icons.account_tree_outlined),
            ),
            _fieldRow(
              _field(_communityController, 'Community',
                  icon: Icons.group_outlined),
              _field(_motherTongueController, 'Mother Tongue',
                  icon: Icons.language),
            ),
            const SizedBox(height: 20),

            // About
            _sectionLabel('About'),
            AppSpacing.gapH12,
            _field(_aboutMeController, 'About the candidate',
                icon: Icons.info_outline, maxLines: 3),
            _field(_familyBgController, 'Family Background',
                icon: Icons.family_restroom, maxLines: 2),
            _fieldRow(
              _field(_fatherOccController, "Father's Occupation",
                  icon: Icons.person_outline),
              _field(_motherOccController, "Mother's Occupation",
                  icon: Icons.person_outline),
            ),
            _field(_siblingsController, 'Siblings',
                icon: Icons.people_outline, hint: 'e.g., 1 elder brother'),
            _field(_interestsController, 'Interests (comma-separated)',
                icon: Icons.interests,
                hint: 'e.g., Travel, Music, Cooking'),
            const SizedBox(height: 20),

            // Photos
            PhotoManagerWidget(
              initialPhotos: _photos,
              maxPhotos: 6,
              onPhotosChanged: (photos) {
                setState(() => _photos = photos);
              },
            ),
            AppSpacing.gapH32,

            // Save button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacredSaffron,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                ),
                child: Text(
                  'Create Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            AppSpacing.gapH24,
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _fieldRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        AppSpacing.gapW12,
        Expanded(child: right),
      ],
    );
  }
}
