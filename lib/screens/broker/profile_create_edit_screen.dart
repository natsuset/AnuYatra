import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/common/widgets/molecules/photo_manager_widget.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Who is creating the profile. Drives ownership fields, the title bar,
/// the "child's phone number" prompt, and whether a candidate user gets
/// auto-created (PRODUCT_PLAN §1.7).
enum ProfileCreateMode { broker, parent, candidate }

/// Form for creating a new candidate profile. Reused by all three owners:
///
/// - `ProfileCreateMode.broker` (default) — broker creates a profile on
///   behalf of a parent client. Sets `brokerIds: [brokerUid]`.
/// - `ProfileCreateMode.parent` — parent creates their child's profile.
///   Captures the child's phone number, auto-creates the candidate user via
///   `UserRepository.registerOrLookupByPhone`, links parent ↔ child with an
///   accepted `childToParent` LinkRequest, and sets `parentUserId` +
///   `candidateUserId` on the profile.
/// - `ProfileCreateMode.candidate` — candidate creates their own profile.
///   Sets `candidateUserId` to themself.
class ProfileCreateEditScreen extends ConsumerStatefulWidget {
  final ProfileCreateMode mode;

  const ProfileCreateEditScreen({
    super.key,
    this.mode = ProfileCreateMode.broker,
  });

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
  // Only used in `ProfileCreateMode.parent` — captures the child's phone
  // number so we can auto-create / link the candidate user.
  final _childPhoneController = TextEditingController();

  Gender _gender = Gender.bride;
  bool _isSaving = false;
  List<String> _photos = [];

  /// Indian mobile number regex, mirrors the one in `AuthNotifier`.
  static final _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

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
    _childPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profileRepo = ref.read(profileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) {
      setState(() => _isSaving = false);
      return;
    }

    final creator = authState.user;
    final now = DateTime.now();
    final interests = _interestsController.text.trim().isNotEmpty
        ? _interestsController.text.split(',').map((s) => s.trim()).toList()
        : <String>[];
    final profileId = const Uuid().v4();
    final name = _nameController.text.trim();

    // Resolve ownership fields per mode.
    String createdByUserId = creator.uid;
    List<String> brokerIds = const [];
    String? parentUserId;
    String? candidateUserId;

    try {
      switch (widget.mode) {
        case ProfileCreateMode.broker:
          brokerIds = [creator.uid];
        case ProfileCreateMode.candidate:
          candidateUserId = creator.uid;
        case ProfileCreateMode.parent:
          parentUserId = creator.uid;
          // Auto-create (or look up) the candidate user from the child's phone.
          final phone = _childPhoneController.text.trim();
          final candidateUser = await userRepo.registerOrLookupByPhone(
            phoneNumber: phone,
            displayName: name,
            role: UserRole.candidate,
          );
          candidateUserId = candidateUser.uid;
          // Pre-accepted childToParent link so the parent's dashboard
          // surfaces this child immediately (no manual acceptance needed —
          // the parent IS the one creating the link).
          await linkRepo.saveLinkRequest(
            LinkRequest(
              id: const Uuid().v4(),
              fromUserId: candidateUser.uid,
              toUserId: creator.uid,
              fromUserName: name,
              toUserName: creator.displayName,
              type: LinkRequestType.childToParent,
              status: LinkRequestStatus.accepted,
              createdAt: now,
              respondedAt: now,
            ),
          );
      }

      final profile = CandidateProfile(
        id: profileId,
        createdByUserId: createdByUserId,
        name: name,
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
        brokerIds: brokerIds,
        parentUserId: parentUserId,
        candidateUserId: candidateUserId,
        createdAt: now,
        updatedAt: now,
      );

      await profileRepo.saveCandidateProfile(profile);

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileCreatedFor(profile.name)),
          backgroundColor: context.palette.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: context.palette.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForMode()),
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
                    context.l10n.save,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
              segments: [
                ButtonSegment(
                  value: Gender.bride,
                  label: Text(context.l10n.bride),
                ),
                ButtonSegment(
                  value: Gender.groom,
                  label: Text(context.l10n.groom),
                ),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                selectedForegroundColor: Theme.of(context).colorScheme.primary,
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
            if (widget.mode == ProfileCreateMode.parent) ...[
              const SizedBox(height: 20),
              _sectionLabel("Child's Contact"),
              AppSpacing.gapH8,
              Text(
                'We\'ll send an invite to this number so your child can claim '
                'their profile when they install the app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.gapH8,
              _field(
                _childPhoneController,
                "Child's phone number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: 'e.g. 9876543210',
                validator: (v) {
                  if (widget.mode != ProfileCreateMode.parent) return null;
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Required';
                  if (!_indianPhoneRegex.hasMatch(t)) {
                    return 'Enter a valid 10-digit Indian mobile number';
                  }
                  return null;
                },
              ),
            ],
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                ),
                child: Text(
                  _titleForMode(),
                  style: const TextStyle(
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

  String _titleForMode() {
    switch (widget.mode) {
      case ProfileCreateMode.broker:
        return 'Create Profile';
      case ProfileCreateMode.parent:
        return "Add My Child's Profile";
      case ProfileCreateMode.candidate:
        return 'My Profile';
    }
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
