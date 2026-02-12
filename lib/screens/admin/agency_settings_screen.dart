import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/core/providers/theme_provider.dart';

/// Agency settings screen for admin users.
/// Edit agency details, manage preferences, invite brokers.
class AgencySettingsScreen extends ConsumerStatefulWidget {
  const AgencySettingsScreen({super.key});

  @override
  ConsumerState<AgencySettingsScreen> createState() =>
      _AgencySettingsScreenState();
}

class _AgencySettingsScreenState extends ConsumerState<AgencySettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();

    // Load agency data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgencyData();
    });
  }

  void _loadAgencyData() {
    final storage = ref.read(localStorageServiceProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final agencyId = authState.user.agencyId;
    if (agencyId == null) return;

    final agency = storage.getAgency(agencyId);
    if (agency != null) {
      _nameController.text = agency.name;
      _descController.text = agency.description;
      _cityController.text = agency.city;
      _stateController.text = agency.state;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);

    final storage = ref.read(localStorageServiceProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final agencyId = authState.user.agencyId;
    if (agencyId == null) return;

    final agency = storage.getAgency(agencyId);
    if (agency != null) {
      final updated = agency.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );
      await storage.saveAgency(updated);
    }

    setState(() {
      _saving = false;
      _editing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agency settings saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final storage = ref.watch(localStorageServiceProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final agencyId = user.agencyId;
    final agency = agencyId != null ? storage.getAgency(agencyId) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Settings'),
        actions: [
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _saveChanges,
              child: _saving
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
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Agency Info Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: AppColors.sacredSaffron),
                    const SizedBox(width: 10),
                    Text(
                      'Agency Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Agency Name', _nameController, _editing),
                const SizedBox(height: 12),
                _buildField('Description', _descController, _editing,
                    maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField('City', _cityController, false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField('State', _stateController, false),
                    ),
                  ],
                ),
                if (agency != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Rating: ${agency.rating}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Specializations
          if (agency != null && agency.specializations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specializations',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: agency.specializations.map((s) {
                      return Chip(
                        label: Text(s),
                        backgroundColor:
                            AppColors.sacredSaffron.withValues(alpha: 0.1),
                        labelStyle: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.sacredSaffron,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Theme toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.sacredSaffron,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dark Mode',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                        v ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeThumbColor: AppColors.sacredSaffron,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Logout
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content:
                        const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool enabled, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
