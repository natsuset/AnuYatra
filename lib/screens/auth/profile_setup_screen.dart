import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/auth/profile_setup_data.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/parent_profile.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Multi-step profile setup wizard.
/// Shows different steps based on selected role.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _draftKeyPrefix = 'profile_setup_draft_';

  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  Timer? _draftDebounce;
  bool _draftRestoreAttempted = false;

  // Common
  final _nameController = TextEditingController();

  // Agency fields
  final _agencyNameController = TextEditingController();
  final _agencyCityController = TextEditingController();
  final _agencyStateController = TextEditingController();
  final _agencyDescController = TextEditingController();
  final _agencyEmailController = TextEditingController();
  final _agencyPhoneController = TextEditingController();
  final _agencyWebsiteController = TextEditingController();
  String _agencySpecializations = '';

  // Broker fields
  final _brokerBioController = TextEditingController();
  final _brokerExpController = TextEditingController();
  final _brokerEmailController = TextEditingController();
  final _brokerOfficeAddrController = TextEditingController();
  final _brokerFeeController = TextEditingController();
  final _brokerWorkingHoursController = TextEditingController();
  String _brokerAreasServed = '';
  String _brokerSpecializations = '';
  String _brokerLanguages = '';

  // Parent fields
  String _lookingFor = 'bride';
  final _parentCityController = TextEditingController();
  final _parentStateController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childEducationController = TextEditingController();
  final _childProfessionController = TextEditingController();
  final _childHeightController = TextEditingController();
  final _fatherOccController = TextEditingController();
  final _motherOccController = TextEditingController();
  final _aboutFamilyController = TextEditingController();
  Diet? _childDiet;
  FamilyType? _familyType;

  // Candidate fields
  final _candidateAgeController = TextEditingController();
  String _candidateGender = 'bride';

  int get _totalSteps {
    final authState = ref.read(authProvider);
    UserRole role = UserRole.parent;
    if (authState is AuthNeedsProfile) {
      role = authState.role;
    }
    return switch (role) {
      UserRole.agencyAdmin => 3,
      UserRole.broker => 3,
      UserRole.parent => 3,
      UserRole.candidate => 2,
    };
  }

  @override
  void initState() {
    super.initState();
    for (final c in _allControllers().values) {
      c.addListener(_scheduleDraftSave);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_draftRestoreAttempted) return;
      _draftRestoreAttempted = true;
      final auth = ref.read(authProvider);
      if (auth is AuthNeedsProfile) {
        await _restoreDraft(auth);
      }
    });
  }

  Map<String, TextEditingController> _allControllers() => {
    'name': _nameController,
    'agencyName': _agencyNameController,
    'agencyCity': _agencyCityController,
    'agencyState': _agencyStateController,
    'agencyDesc': _agencyDescController,
    'agencyEmail': _agencyEmailController,
    'agencyPhone': _agencyPhoneController,
    'agencyWebsite': _agencyWebsiteController,
    'brokerBio': _brokerBioController,
    'brokerExp': _brokerExpController,
    'brokerEmail': _brokerEmailController,
    'brokerOfficeAddr': _brokerOfficeAddrController,
    'brokerFee': _brokerFeeController,
    'brokerWorkingHours': _brokerWorkingHoursController,
    'parentCity': _parentCityController,
    'parentState': _parentStateController,
    'parentEmail': _parentEmailController,
    'childName': _childNameController,
    'childEducation': _childEducationController,
    'childProfession': _childProfessionController,
    'childHeight': _childHeightController,
    'fatherOcc': _fatherOccController,
    'motherOcc': _motherOccController,
    'aboutFamily': _aboutFamilyController,
    'candidateAge': _candidateAgeController,
  };

  String _draftKey(AuthNeedsProfile auth) =>
      '$_draftKeyPrefix${auth.phoneNumber}_${auth.role.name}';

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), _persistDraft);
  }

  Future<void> _persistDraft() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthNeedsProfile) return;
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{
      for (final e in _allControllers().entries) e.key: e.value.text,
      '_lookingFor': _lookingFor,
      '_agencySpecializations': _agencySpecializations,
      '_brokerAreasServed': _brokerAreasServed,
      '_brokerSpecializations': _brokerSpecializations,
      '_brokerLanguages': _brokerLanguages,
      '_candidateGender': _candidateGender,
    };
    final hasAny = data.values.any((v) => v.trim().isNotEmpty);
    if (!hasAny) {
      await prefs.remove(_draftKey(auth));
      return;
    }
    await prefs.setString(_draftKey(auth), jsonEncode(data));
  }

  Future<void> _restoreDraft(AuthNeedsProfile auth) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(auth));
    if (raw == null) return;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_draftKey(auth));
      return;
    }
    for (final entry in _allControllers().entries) {
      final v = data[entry.key];
      if (v is String && v.isNotEmpty) entry.value.text = v;
    }
    if (!mounted) return;
    setState(() {
      _lookingFor = (data['_lookingFor'] as String?) ?? _lookingFor;
      _agencySpecializations =
          (data['_agencySpecializations'] as String?) ?? '';
      _brokerAreasServed = (data['_brokerAreasServed'] as String?) ?? '';
      _brokerSpecializations =
          (data['_brokerSpecializations'] as String?) ?? '';
      _brokerLanguages = (data['_brokerLanguages'] as String?) ?? '';
      _candidateGender =
          (data['_candidateGender'] as String?) ?? _candidateGender;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Draft restored from your last session'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Discard',
          onPressed: _clearDraft,
        ),
      ),
    );
  }

  Future<void> _clearDraft() async {
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    if (auth is AuthNeedsProfile) {
      await prefs.remove(_draftKey(auth));
    }
    for (final c in _allControllers().values) {
      c.clear();
    }
    if (!mounted) return;
    setState(() {
      _lookingFor = 'bride';
      _agencySpecializations = '';
      _brokerAreasServed = '';
      _brokerSpecializations = '';
      _brokerLanguages = '';
      _candidateGender = 'bride';
      _childDiet = null;
      _familyType = null;
    });
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    for (final c in _allControllers().values) {
      c.removeListener(_scheduleDraftSave);
    }
    _pageController.dispose();
    _nameController.dispose();
    _agencyNameController.dispose();
    _agencyCityController.dispose();
    _agencyStateController.dispose();
    _agencyDescController.dispose();
    _agencyEmailController.dispose();
    _agencyPhoneController.dispose();
    _agencyWebsiteController.dispose();
    _brokerBioController.dispose();
    _brokerExpController.dispose();
    _brokerEmailController.dispose();
    _brokerOfficeAddrController.dispose();
    _brokerFeeController.dispose();
    _brokerWorkingHoursController.dispose();
    _parentCityController.dispose();
    _parentStateController.dispose();
    _parentEmailController.dispose();
    _childNameController.dispose();
    _childEducationController.dispose();
    _childProfessionController.dispose();
    _childHeightController.dispose();
    _fatherOccController.dispose();
    _motherOccController.dispose();
    _aboutFamilyController.dispose();
    _candidateAgeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build a role-specific [ProfileSetupData] from the form controllers.
  /// Only fields relevant to [role] are read.
  ProfileSetupData _buildSetupData(UserRole role) {
    List<String> splitCsv(String raw) => raw.isEmpty
        ? const []
        : raw.split(',').map((s) => s.trim()).toList();

    switch (role) {
      case UserRole.agencyAdmin:
        return AgencySetupData(
          name: _agencyNameController.text.trim().isEmpty
              ? null
              : _agencyNameController.text.trim(),
          city: _agencyCityController.text.trim(),
          state: _agencyStateController.text.trim(),
          description: _agencyDescController.text.trim(),
          specializations: splitCsv(_agencySpecializations),
        );
      case UserRole.broker:
        return BrokerSetupData(
          bio: _brokerBioController.text.trim(),
          specializations: splitCsv(_brokerSpecializations),
          areasServed: splitCsv(_brokerAreasServed),
          experienceYears:
              int.tryParse(_brokerExpController.text.trim()) ?? 0,
        );
      case UserRole.parent:
        return ParentSetupData(
          lookingFor: _lookingFor,
          city: _parentCityController.text.trim(),
          state: _parentStateController.text.trim(),
        );
      case UserRole.candidate:
        return CandidateSetupData(
          age: int.tryParse(_candidateAgeController.text.trim()),
          gender: _candidateGender,
        );
    }
  }

  void _submitProfile(String uid, UserRole role) {
    if (!_formKey.currentState!.validate()) return;

    final data = _buildSetupData(role);

    // Submit basic registration through auth provider
    ref.read(authProvider.notifier).completeProfileSetup(
      uid: uid,
      displayName: _nameController.text.trim(),
      data: data,
    );

    // Save enriched fields after a short delay to let auth complete
    Future.delayed(const Duration(milliseconds: 600), () async {
      await _saveEnrichedFields(uid, role);
      final auth = ref.read(authProvider);
      if (auth is AuthNeedsProfile) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_draftKey(auth));
      } else {
        final phone = (auth is AuthAuthenticated) ? auth.user.phoneNumber : '';
        if (phone.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('$_draftKeyPrefix${phone}_${role.name}');
        }
      }
    });
  }

  Future<void> _saveEnrichedFields(String uid, UserRole role) async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final agencyRepo = ref.read(agencyRepositoryProvider);

    switch (role) {
      case UserRole.parent:
        final existing = await profileRepo.getParentProfile(uid);
        if (existing != null) {
          final updated = existing.copyWith(
            email: _parentEmailController.text.trim().isNotEmpty
                ? _parentEmailController.text.trim()
                : null,
            childName: _childNameController.text.trim().isNotEmpty
                ? _childNameController.text.trim()
                : null,
            childEducation: _childEducationController.text.trim().isNotEmpty
                ? _childEducationController.text.trim()
                : null,
            childProfession: _childProfessionController.text.trim().isNotEmpty
                ? _childProfessionController.text.trim()
                : null,
            childHeight: _childHeightController.text.trim().isNotEmpty
                ? _childHeightController.text.trim()
                : null,
            childDiet: _childDiet,
            fatherOccupation: _fatherOccController.text.trim().isNotEmpty
                ? _fatherOccController.text.trim()
                : null,
            motherOccupation: _motherOccController.text.trim().isNotEmpty
                ? _motherOccController.text.trim()
                : null,
            aboutFamily: _aboutFamilyController.text.trim().isNotEmpty
                ? _aboutFamilyController.text.trim()
                : null,
            familyType: _familyType,
          );
          await profileRepo.saveParentProfile(updated);
        }
        break;

      case UserRole.broker:
        final existing = await brokerRepo.getBrokerProfile(uid);
        if (existing != null) {
          final updated = existing.copyWith(
            email: _brokerEmailController.text.trim().isNotEmpty
                ? _brokerEmailController.text.trim()
                : null,
            officeAddress: _brokerOfficeAddrController.text.trim().isNotEmpty
                ? _brokerOfficeAddrController.text.trim()
                : null,
            feeStructure: _brokerFeeController.text.trim().isNotEmpty
                ? _brokerFeeController.text.trim()
                : null,
            workingHours: _brokerWorkingHoursController.text.trim().isNotEmpty
                ? _brokerWorkingHoursController.text.trim()
                : null,
            languagesSpoken: _brokerLanguages.isNotEmpty
                ? _brokerLanguages.split(',').map((s) => s.trim()).toList()
                : null,
          );
          await brokerRepo.saveBrokerProfile(updated);
        }
        break;

      case UserRole.agencyAdmin:
        final user = await userRepo.getUser(uid);
        if (user?.agencyId != null) {
          final agency = await agencyRepo.getAgency(user!.agencyId!);
          if (agency != null) {
            final updated = agency.copyWith(
              email: _agencyEmailController.text.trim().isNotEmpty
                  ? _agencyEmailController.text.trim()
                  : null,
              phone: _agencyPhoneController.text.trim().isNotEmpty
                  ? _agencyPhoneController.text.trim()
                  : null,
              website: _agencyWebsiteController.text.trim().isNotEmpty
                  ? _agencyWebsiteController.text.trim()
                  : null,
            );
            await agencyRepo.saveAgency(updated);
          }
        }
        break;

      case UserRole.candidate:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    String uid = '';
    UserRole role = UserRole.parent;
    if (authState is AuthNeedsProfile) {
      uid = authState.uid;
      role = authState.role;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.completeProfile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              _buildStepIndicator(theme, role),

              // Step content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildSteps(theme, role),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: AppSpacing.allLg,
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.roundedMd,
                            ),
                          ),
                          child: Text(context.l10n.back),
                        ),
                      ),
                    if (_currentStep > 0) AppSpacing.gapW12,
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_currentStep < _totalSteps - 1) {
                                  _nextStep();
                                } else {
                                  _submitProfile(uid, role);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedMd,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep < _totalSteps - 1
                                    ? context.l10n.next
                                    : context.l10n.getStarted,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, UserRole role) {
    final total = _totalSteps;
    final stepLabels = switch (role) {
      UserRole.agencyAdmin => [context.l10n.stepBasicInfo, context.l10n.stepAgencyDetails, context.l10n.stepContact],
      UserRole.broker => [context.l10n.stepBasicInfo, context.l10n.experienceLabel, context.l10n.stepBusinessDetails],
      UserRole.parent => [context.l10n.stepBasicInfo, context.l10n.stepChildDetails, context.l10n.stepFamilyDetails],
      UserRole.candidate => [context.l10n.stepBasicInfo, context.l10n.stepPersonal],
    };

    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.lg,
        top: AppSpacing.xs,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Step dots with connecting lines
          Row(
            children: List.generate(total * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: stepBefore < _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                );
              }
              final step = index ~/ 2;
              final isActive = step <= _currentStep;
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: step < _currentStep
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              );
            }),
          ),
          AppSpacing.gapH8,
          // Step label
          Text(
            stepLabels[_currentStep],
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(ThemeData theme, UserRole role) {
    return switch (role) {
      UserRole.agencyAdmin => [
          _buildStep1Common(theme, role),
          _buildAgencyStep2(theme),
          _buildAgencyStep3(theme),
        ],
      UserRole.broker => [
          _buildStep1Common(theme, role),
          _buildBrokerStep2(theme),
          _buildBrokerStep3(theme),
        ],
      UserRole.parent => [
          _buildStep1Common(theme, role),
          _buildParentStep2(theme),
          _buildParentStep3(theme),
        ],
      UserRole.candidate => [
          _buildStep1Common(theme, role),
          _buildCandidateStep2(theme),
        ],
    };
  }

  // Step 1: Common name + role-specific basic fields
  Widget _buildStep1Common(ThemeData theme, UserRole role) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Text(
            context.l10n.settingUpAs(role.displayName),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppSpacing.gapH24,
        _buildTextField(
          controller: _nameController,
          label: context.l10n.yourName,
          hint: context.l10n.enterYourFullName,
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.isEmpty ? context.l10n.nameRequired : null,
        ),
        AppSpacing.gapH16,
        // Role-specific basic fields
        ...switch (role) {
          UserRole.agencyAdmin => [
              _buildTextField(
                controller: _agencyNameController,
                label: context.l10n.agencyNameLabel,
                hint: 'e.g., Shubh Vivah Matrimony',
                icon: Icons.business,
                validator: (v) =>
                    v == null || v.isEmpty ? context.l10n.agencyNameRequired : null,
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _agencyCityController,
                      label: context.l10n.cityLabel,
                      hint: 'Mumbai',
                      icon: Icons.location_city,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _buildTextField(
                      controller: _agencyStateController,
                      label: context.l10n.stateLabel,
                      hint: 'Maharashtra',
                      icon: Icons.map,
                    ),
                  ),
                ],
              ),
            ],
          UserRole.broker => [
              _buildTextField(
                controller: _brokerBioController,
                label: context.l10n.aboutYou,
                hint: context.l10n.aboutYouHint,
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              AppSpacing.gapH16,
              _buildTextField(
                controller: _brokerExpController,
                label: context.l10n.yearsOfExperience,
                hint: 'e.g., 5',
                icon: Icons.work_outline,
                keyboardType: TextInputType.number,
              ),
            ],
          UserRole.parent => [
              Text(
                context.l10n.lookingForA,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapH8,
              Row(
                children: [
                  Expanded(
                    child: _RadioCard(
                      label: context.l10n.bride,
                      icon: Icons.female,
                      isSelected: _lookingFor == 'bride',
                      onTap: () => setState(() => _lookingFor = 'bride'),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _RadioCard(
                      label: context.l10n.groom,
                      icon: Icons.male,
                      isSelected: _lookingFor == 'groom',
                      onTap: () => setState(() => _lookingFor = 'groom'),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _parentCityController,
                      label: context.l10n.cityLabel,
                      hint: 'Mumbai',
                      icon: Icons.location_city,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _buildTextField(
                      controller: _parentStateController,
                      label: context.l10n.stateLabel,
                      hint: 'Maharashtra',
                      icon: Icons.map,
                    ),
                  ),
                ],
              ),
            ],
          UserRole.candidate => [
              Text(
                context.l10n.iAmA,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapH8,
              Row(
                children: [
                  Expanded(
                    child: _RadioCard(
                      label: context.l10n.bride,
                      icon: Icons.female,
                      isSelected: _candidateGender == 'bride',
                      onTap: () =>
                          setState(() => _candidateGender = 'bride'),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: _RadioCard(
                      label: context.l10n.groom,
                      icon: Icons.male,
                      isSelected: _candidateGender == 'groom',
                      onTap: () =>
                          setState(() => _candidateGender = 'groom'),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              _buildTextField(
                controller: _candidateAgeController,
                label: context.l10n.yourAge,
                hint: 'e.g., 26',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
        },
      ],
    );
  }

  // Agency Step 2: Description and specializations
  Widget _buildAgencyStep2(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.stepAgencyDetails),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _agencyDescController,
          label: context.l10n.descriptionLabel,
          hint: 'Describe your agency and services...',
          icon: Icons.description,
          maxLines: 4,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: TextEditingController(),
          label: 'Specializations (comma-separated)',
          hint: 'e.g., Hindu, Gujarati, Jain, NRI',
          icon: Icons.category_outlined,
          onChanged: (v) => _agencySpecializations = v,
        ),
      ],
    );
  }

  // Agency Step 3: Contact info
  Widget _buildAgencyStep3(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.contactInformationSection),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _agencyEmailController,
          label: context.l10n.emailLabel,
          hint: 'agency@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _agencyPhoneController,
          label: 'Office Phone',
          hint: '+91 XXXXXXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _agencyWebsiteController,
          label: 'Website (optional)',
          hint: 'https://www.example.com',
          icon: Icons.language,
        ),
        AppSpacing.gapH16,
        Text(
          'You can add more details later from Agency Settings',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Broker Step 2: Areas and specializations
  Widget _buildBrokerStep2(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.experienceExpertiseSection),
        AppSpacing.gapH16,
        _buildTextField(
          controller: TextEditingController(),
          label: 'Areas Served (comma-separated)',
          hint: 'e.g., Mumbai, Pune, Thane',
          icon: Icons.location_on_outlined,
          onChanged: (v) => _brokerAreasServed = v,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: TextEditingController(),
          label: 'Specializations (comma-separated)',
          hint: 'e.g., Hindu, Gujarati, Jain',
          icon: Icons.category_outlined,
          onChanged: (v) => _brokerSpecializations = v,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: TextEditingController(),
          label: 'Languages Spoken (comma-separated)',
          hint: 'e.g., Hindi, Marathi, English',
          icon: Icons.language,
          onChanged: (v) => _brokerLanguages = v,
        ),
      ],
    );
  }

  // Broker Step 3: Business details
  Widget _buildBrokerStep3(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.stepBusinessDetails),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _brokerEmailController,
          label: context.l10n.emailLabel,
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _brokerOfficeAddrController,
          label: 'Office Address (optional)',
          hint: 'Your office location',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _brokerFeeController,
          label: 'Fee Structure (optional)',
          hint: 'e.g., Free consultation, Rs. 5000 registration',
          icon: Icons.currency_rupee,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _brokerWorkingHoursController,
          label: 'Working Hours (optional)',
          hint: 'e.g., Mon-Sat 10am - 7pm',
          icon: Icons.schedule,
        ),
      ],
    );
  }

  // Parent Step 2: Child details
  Widget _buildParentStep2(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.childDetailsSection),
        AppSpacing.gapH8,
        Text(
          'This information helps brokers find suitable matches',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _childNameController,
          label: context.l10n.childNameLabel,
          hint: context.l10n.fullNameHint,
          icon: Icons.person_outline,
        ),
        AppSpacing.gapH16,
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _childHeightController,
                label: context.l10n.heightLabel,
                hint: "e.g., 5'6\"",
                icon: Icons.height,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: DropdownButtonFormField<Diet>(
                initialValue: _childDiet,
                  decoration: InputDecoration(
                  labelText: context.l10n.dietLabel,
                  prefixIcon: const Icon(Icons.restaurant_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 14),
                ),
                items: Diet.values.map((d) {
                  final label = switch (d) {
                    Diet.vegetarian => 'Vegetarian',
                    Diet.nonVegetarian => 'Non-Veg',
                    Diet.eggetarian => 'Eggetarian',
                    Diet.vegan => 'Vegan',
                    Diet.jain => 'Jain',
                  };
                  return DropdownMenuItem(value: d, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _childDiet = v),
              ),
            ),
          ],
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _childEducationController,
          label: context.l10n.educationLabel,
          hint: 'e.g., B.Tech, MBA, MBBS',
          icon: Icons.school_outlined,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _childProfessionController,
          label: context.l10n.professionLabel,
          hint: 'e.g., Software Engineer, Doctor',
          icon: Icons.work_outline,
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _parentEmailController,
          label: 'Your Email (optional)',
          hint: 'email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // Parent Step 3: Family details
  Widget _buildParentStep3(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.familyInformationSection),
        AppSpacing.gapH16,
        DropdownButtonFormField<FamilyType>(
          initialValue: _familyType,
          decoration: InputDecoration(
            labelText: context.l10n.familyTypeLabel,
            prefixIcon: const Icon(Icons.family_restroom, size: 20),
            border: OutlineInputBorder(
              borderRadius: AppSpacing.roundedMd,
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
          ),
          items: FamilyType.values.map((t) {
            final label = t == FamilyType.joint ? 'Joint Family' : 'Nuclear Family';
            return DropdownMenuItem(value: t, child: Text(label));
          }).toList(),
          onChanged: (v) => setState(() => _familyType = v),
        ),
        AppSpacing.gapH16,
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _fatherOccController,
                label: context.l10n.fatherOccupationLabel,
                hint: 'e.g., Businessman',
                icon: Icons.person_outline,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _buildTextField(
                controller: _motherOccController,
                label: context.l10n.motherOccupationLabel,
                hint: 'e.g., Homemaker',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        AppSpacing.gapH16,
        _buildTextField(
          controller: _aboutFamilyController,
          label: context.l10n.aboutFamilyLabel,
          hint: 'Briefly describe your family background...',
          icon: Icons.info_outline,
          maxLines: 3,
        ),
        AppSpacing.gapH16,
        Text(
          context.l10n.canCompleteLater,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Candidate Step 2: Personal details
  Widget _buildCandidateStep2(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        _buildSectionHeader(theme, context.l10n.personalInformationSection),
        AppSpacing.gapH8,
        Text(
          context.l10n.candidateLinkHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapH24,
        Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: context.palette.info.withValues(alpha: 0.08),
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: context.palette.info.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: context.palette.info, size: 20),
              AppSpacing.gapW12,
              Expanded(
                child: Text(
                  context.l10n.candidateInfoBox,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.info,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: AppSpacing.verticalMd,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              AppSpacing.gapH8,
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
