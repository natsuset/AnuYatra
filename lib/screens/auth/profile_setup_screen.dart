import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

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
  void dispose() {
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

  void _submitProfile(String uid, UserRole role) {
    if (!_formKey.currentState!.validate()) return;

    // Submit basic registration through auth provider
    ref.read(authProvider.notifier).completeProfileSetup(
      uid: uid,
      displayName: _nameController.text.trim(),
      role: role,
      agencyName: _agencyNameController.text.trim(),
      agencyCity: _agencyCityController.text.trim(),
      agencyState: _agencyStateController.text.trim(),
      agencyDescription: _agencyDescController.text.trim(),
      agencySpecializations: _agencySpecializations.isNotEmpty
          ? _agencySpecializations.split(',').map((s) => s.trim()).toList()
          : null,
      brokerBio: _brokerBioController.text.trim(),
      brokerExperienceYears: int.tryParse(_brokerExpController.text.trim()),
      brokerAreasServed: _brokerAreasServed.isNotEmpty
          ? _brokerAreasServed.split(',').map((s) => s.trim()).toList()
          : null,
      brokerSpecializations: _brokerSpecializations.isNotEmpty
          ? _brokerSpecializations.split(',').map((s) => s.trim()).toList()
          : null,
      lookingFor: _lookingFor,
      parentCity: _parentCityController.text.trim(),
      parentState: _parentStateController.text.trim(),
      candidateAge: int.tryParse(_candidateAgeController.text.trim()),
      candidateGender: _candidateGender,
    );

    // Save enriched fields after a short delay to let auth complete
    Future.delayed(const Duration(milliseconds: 600), () {
      _saveEnrichedFields(uid, role);
    });
  }

  Future<void> _saveEnrichedFields(String uid, UserRole role) async {
    final storage = ref.read(localStorageServiceProvider);

    switch (role) {
      case UserRole.parent:
        final existing = storage.getParentProfile(uid);
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
          await storage.saveParentProfile(updated);
        }
        break;

      case UserRole.broker:
        final existing = storage.getBrokerProfile(uid);
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
          await storage.saveBrokerProfile(updated);
        }
        break;

      case UserRole.agencyAdmin:
        // Agency enriched fields are saved by auth provider via createAgency
        // Additional fields can be saved to agency here
        final user = storage.getUser(uid);
        if (user?.agencyId != null) {
          final agency = storage.getAgency(user!.agencyId!);
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
            await storage.saveAgency(updated);
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
        title: const Text('Complete Your Profile'),
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
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
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
                          backgroundColor: AppColors.sacredSaffron,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                    ? 'Next'
                                    : 'Get Started',
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
      UserRole.agencyAdmin => ['Basic Info', 'Agency Details', 'Contact'],
      UserRole.broker => ['Basic Info', 'Experience', 'Business Details'],
      UserRole.parent => ['Basic Info', 'Child Details', 'Family Details'],
      UserRole.candidate => ['Basic Info', 'Personal'],
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                        ? AppColors.sacredSaffron
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
                      ? AppColors.sacredSaffron
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
          const SizedBox(height: 8),
          // Step label
          Text(
            stepLabels[_currentStep],
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.sacredSaffron,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.sacredSaffron.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Setting up as: ${role.displayName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.sacredSaffron,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _nameController,
          label: 'Your Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        // Role-specific basic fields
        ...switch (role) {
          UserRole.agencyAdmin => [
              _buildTextField(
                controller: _agencyNameController,
                label: 'Agency Name',
                hint: 'e.g., Shubh Vivah Matrimony',
                icon: Icons.business,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Agency name is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _agencyCityController,
                      label: 'City',
                      hint: 'Mumbai',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _agencyStateController,
                      label: 'State',
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
                label: 'About You',
                hint: 'Tell families about your matchmaking experience...',
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _brokerExpController,
                label: 'Years of Experience',
                hint: 'e.g., 5',
                icon: Icons.work_outline,
                keyboardType: TextInputType.number,
              ),
            ],
          UserRole.parent => [
              Text(
                'Looking for a',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RadioCard(
                      label: 'Bride',
                      icon: Icons.female,
                      isSelected: _lookingFor == 'bride',
                      onTap: () => setState(() => _lookingFor = 'bride'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RadioCard(
                      label: 'Groom',
                      icon: Icons.male,
                      isSelected: _lookingFor == 'groom',
                      onTap: () => setState(() => _lookingFor = 'groom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _parentCityController,
                      label: 'City',
                      hint: 'Mumbai',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _parentStateController,
                      label: 'State',
                      hint: 'Maharashtra',
                      icon: Icons.map,
                    ),
                  ),
                ],
              ),
            ],
          UserRole.candidate => [
              Text(
                'I am a',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RadioCard(
                      label: 'Bride',
                      icon: Icons.female,
                      isSelected: _candidateGender == 'bride',
                      onTap: () =>
                          setState(() => _candidateGender = 'bride'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RadioCard(
                      label: 'Groom',
                      icon: Icons.male,
                      isSelected: _candidateGender == 'groom',
                      onTap: () =>
                          setState(() => _candidateGender = 'groom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _candidateAgeController,
                label: 'Your Age',
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Agency Details'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _agencyDescController,
          label: 'Description',
          hint: 'Describe your agency and services...',
          icon: Icons.description,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Contact Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _agencyEmailController,
          label: 'Email',
          hint: 'agency@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _agencyPhoneController,
          label: 'Office Phone',
          hint: '+91 XXXXXXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _agencyWebsiteController,
          label: 'Website (optional)',
          hint: 'https://www.example.com',
          icon: Icons.language,
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Experience & Expertise'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: TextEditingController(),
          label: 'Areas Served (comma-separated)',
          hint: 'e.g., Mumbai, Pune, Thane',
          icon: Icons.location_on_outlined,
          onChanged: (v) => _brokerAreasServed = v,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: TextEditingController(),
          label: 'Specializations (comma-separated)',
          hint: 'e.g., Hindu, Gujarati, Jain',
          icon: Icons.category_outlined,
          onChanged: (v) => _brokerSpecializations = v,
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Business Details'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brokerEmailController,
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brokerOfficeAddrController,
          label: 'Office Address (optional)',
          hint: 'Your office location',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brokerFeeController,
          label: 'Fee Structure (optional)',
          hint: 'e.g., Free consultation, Rs. 5000 registration',
          icon: Icons.currency_rupee,
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, "Your Child's Details"),
        const SizedBox(height: 8),
        Text(
          'This information helps brokers find suitable matches',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _childNameController,
          label: "Child's Name",
          hint: 'Full name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _childHeightController,
                label: 'Height',
                hint: "e.g., 5'6\"",
                icon: Icons.height,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Diet>(
                initialValue: _childDiet,
                decoration: InputDecoration(
                  labelText: 'Diet',
                  prefixIcon: const Icon(Icons.restaurant_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _childEducationController,
          label: 'Education',
          hint: 'e.g., B.Tech, MBA, MBBS',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _childProfessionController,
          label: 'Profession',
          hint: 'e.g., Software Engineer, Doctor',
          icon: Icons.work_outline,
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Family Information'),
        const SizedBox(height: 16),
        DropdownButtonFormField<FamilyType>(
          initialValue: _familyType,
          decoration: InputDecoration(
            labelText: 'Family Type',
            prefixIcon: const Icon(Icons.family_restroom, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
          items: FamilyType.values.map((t) {
            final label = t == FamilyType.joint ? 'Joint Family' : 'Nuclear Family';
            return DropdownMenuItem(value: t, child: Text(label));
          }).toList(),
          onChanged: (v) => setState(() => _familyType = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _fatherOccController,
                label: "Father's Occupation",
                hint: 'e.g., Businessman',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _motherOccController,
                label: "Mother's Occupation",
                hint: 'e.g., Homemaker',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _aboutFamilyController,
          label: 'About Family',
          hint: 'Briefly describe your family background...',
          icon: Icons.info_outline,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'You can complete more details from your profile later',
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSectionHeader(theme, 'Personal Information'),
        const SizedBox(height: 8),
        Text(
          'You can link to your parent later and they can fill detailed profile information',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'After creating your account, link to your parent from the Home screen. Your parent and broker will manage detailed profile information.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
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
            color: AppColors.sacredSaffron,
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
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ? AppColors.sacredSaffron.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.sacredSaffron : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.sacredSaffron
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.sacredSaffron
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
