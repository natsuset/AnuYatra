import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Role-specific profile creation form.
/// Shows different fields based on role.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Agency fields
  final _agencyNameController = TextEditingController();
  final _agencyCityController = TextEditingController();
  final _agencyStateController = TextEditingController();
  final _agencyDescController = TextEditingController();

  // Broker fields
  final _brokerBioController = TextEditingController();
  final _brokerExpController = TextEditingController();
  final _brokerAreasController = TextEditingController();
  final _brokerSpecsController = TextEditingController();
  String _brokerAreasServed = '';
  String _brokerSpecializations = '';

  // Parent fields
  String _lookingFor = 'bride';
  final _parentCityController = TextEditingController();
  final _parentStateController = TextEditingController();

  // Candidate fields
  final _candidateAgeController = TextEditingController();
  String _candidateGender = 'bride';

  @override
  void dispose() {
    _nameController.dispose();
    _agencyNameController.dispose();
    _agencyCityController.dispose();
    _agencyStateController.dispose();
    _agencyDescController.dispose();
    _brokerBioController.dispose();
    _brokerExpController.dispose();
    _brokerAreasController.dispose();
    _brokerSpecsController.dispose();
    _parentCityController.dispose();
    _parentStateController.dispose();
    _candidateAgeController.dispose();
    super.dispose();
  }

  void _submitProfile(String uid, UserRole role) {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).completeProfileSetup(
      uid: uid,
      displayName: _nameController.text.trim(),
      role: role,
      // Agency
      agencyName: _agencyNameController.text.trim(),
      agencyCity: _agencyCityController.text.trim(),
      agencyState: _agencyStateController.text.trim(),
      agencyDescription: _agencyDescController.text.trim(),
      agencySpecializations: _brokerSpecializations.isNotEmpty
          ? _brokerSpecializations.split(',').map((s) => s.trim()).toList()
          : null,
      // Broker
      brokerBio: _brokerBioController.text.trim(),
      brokerExperienceYears: int.tryParse(_brokerExpController.text.trim()),
      brokerAreasServed: _brokerAreasServed.isNotEmpty
          ? _brokerAreasServed.split(',').map((s) => s.trim()).toList()
          : null,
      brokerSpecializations: _brokerSpecializations.isNotEmpty
          ? _brokerSpecializations.split(',').map((s) => s.trim()).toList()
          : null,
      // Parent
      lookingFor: _lookingFor,
      parentCity: _parentCityController.text.trim(),
      parentState: _parentStateController.text.trim(),
      // Candidate
      candidateAge: int.tryParse(_candidateAgeController.text.trim()),
      candidateGender: _candidateGender,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    // Get uid and role from auth state
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
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Role badge
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

              // Common: Name
              _buildTextField(
                controller: _nameController,
                label: 'Your Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Role-specific fields
              ...switch (role) {
                UserRole.agencyAdmin => _buildAgencyFields(theme),
                UserRole.broker => _buildBrokerFields(theme),
                UserRole.parent => _buildParentFields(theme),
                UserRole.candidate => _buildCandidateFields(theme),
              },

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : () => _submitProfile(uid, role),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredSaffron,
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
                      : const Text(
                          'Get Started',
                          style: TextStyle(
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
      ),
    );
  }

  List<Widget> _buildAgencyFields(ThemeData theme) => [
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _agencyDescController,
          label: 'Description',
          hint: 'Describe your agency...',
          icon: Icons.description,
          maxLines: 3,
        ),
      ];

  List<Widget> _buildBrokerFields(ThemeData theme) => [
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brokerAreasController,
          label: 'Areas Served (comma-separated)',
          hint: 'e.g., Mumbai, Pune, Thane',
          icon: Icons.location_on_outlined,
          onChanged: (v) => _brokerAreasServed = v,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brokerSpecsController,
          label: 'Specializations (comma-separated)',
          hint: 'e.g., Hindu, Gujarati, Jain',
          icon: Icons.category_outlined,
          onChanged: (v) => _brokerSpecializations = v,
        ),
      ];

  List<Widget> _buildParentFields(ThemeData theme) => [
        // Looking for
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
      ];

  List<Widget> _buildCandidateFields(ThemeData theme) => [
        // Gender
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
                onTap: () => setState(() => _candidateGender = 'bride'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RadioCard(
                label: 'Groom',
                icon: Icons.male,
                isSelected: _candidateGender == 'groom',
                onTap: () => setState(() => _candidateGender = 'groom'),
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
      ];

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              color: isSelected
                  ? AppColors.sacredSaffron
                  : Colors.transparent,
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
