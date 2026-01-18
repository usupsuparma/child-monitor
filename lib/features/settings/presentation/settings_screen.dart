import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/constants.dart';
import '../../../core/services/services.dart';
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(
        timerService: context.read<TimerService>(),
        permissionService: context.read<PermissionService>(),
      )..init(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Timer Settings'),
              const SizedBox(height: 12),
              _buildTimerCard(context, state),
              const SizedBox(height: 24),
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 12),
              _buildNotificationCard(context, state),
              const SizedBox(height: 24),
              _buildSectionTitle('Permissions'),
              const SizedBox(height: 12),
              _buildPermissionsCard(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context, SettingsState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTimePickerTile(
            context: context,
            icon: Icons.phone_android,
            iconColor: AppColors.screenTimeColor,
            title: 'Screen Time',
            subtitle: 'Duration before break',
            currentDuration: state.settings.screenTime,
            onChanged: (duration) {
              context.read<SettingsCubit>().updateScreenTime(duration);
            },
          ),
          const Divider(color: AppColors.backgroundLight, height: 1),
          _buildTimePickerTile(
            context: context,
            icon: Icons.bedtime_outlined,
            iconColor: AppColors.breakTimeColor,
            title: 'Break Time',
            subtitle: 'Duration of break',
            currentDuration: state.settings.breakTime,
            onChanged: (duration) {
              context.read<SettingsCubit>().updateBreakTime(duration);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Duration currentDuration,
    required ValueChanged<Duration> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: GestureDetector(
        onTap: () => _showDurationPicker(context, currentDuration, onChanged),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${currentDuration.inMinutes} min',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context,
    Duration currentDuration,
    ValueChanged<Duration> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int selectedMinutes = currentDuration.inMinutes;
        final textController = TextEditingController(
          text: selectedMinutes.toString(),
        );

        return StatefulBuilder(
          builder: (context, setState) {
            void updateMinutes(int newValue) {
              if (newValue >= 1 && newValue <= 180) {
                setState(() {
                  selectedMinutes = newValue;
                  textController.text = newValue.toString();
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Duration',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Min: 1 min • Max: 180 min',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main time control with +/- buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus 5 button
                        _buildCircleButton(
                          icon: Icons.remove,
                          label: '-5',
                          onTap: () => updateMinutes(selectedMinutes - 5),
                        ),
                        const SizedBox(width: 8),
                        // Minus 1 button
                        _buildCircleButton(
                          icon: Icons.remove,
                          label: '-1',
                          onTap: () => updateMinutes(selectedMinutes - 1),
                          small: true,
                        ),
                        const SizedBox(width: 16),

                        // Custom input field
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: textController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              suffixText: 'min',
                              suffixStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null &&
                                  parsed >= 1 &&
                                  parsed <= 180) {
                                setState(() => selectedMinutes = parsed);
                              }
                            },
                            onSubmitted: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                updateMinutes(parsed.clamp(1, 180));
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 16),
                        // Plus 1 button
                        _buildCircleButton(
                          icon: Icons.add,
                          label: '+1',
                          onTap: () => updateMinutes(selectedMinutes + 1),
                          small: true,
                        ),
                        const SizedBox(width: 8),
                        // Plus 5 button
                        _buildCircleButton(
                          icon: Icons.add,
                          label: '+5',
                          onTap: () => updateMinutes(selectedMinutes + 5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Preset buttons
                    const Text(
                      'Quick Select',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [1, 5, 10, 15, 20, 30, 45, 60, 90, 120].map((
                        minutes,
                      ) {
                        final isSelected = selectedMinutes == minutes;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMinutes = minutes;
                              textController.text = minutes.toString();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$minutes',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final finalValue = selectedMinutes.clamp(1, 180);
                          onChanged(Duration(minutes: finalValue));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 40 : 48,
        height: small ? 40 : 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: small ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, SettingsState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.volume_up,
            iconColor: AppColors.info,
            title: 'Sound',
            subtitle: 'Play sound when timer expires',
            value: state.settings.soundEnabled,
            onChanged: (value) {
              context.read<SettingsCubit>().toggleSound();
            },
          ),
          const Divider(color: AppColors.backgroundLight, height: 1),
          _buildSwitchTile(
            icon: Icons.vibration,
            iconColor: AppColors.warning,
            title: 'Vibration',
            subtitle: 'Vibrate when timer expires',
            value: state.settings.vibrationEnabled,
            onChanged: (value) {
              context.read<SettingsCubit>().toggleVibration();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildPermissionsCard(BuildContext context, SettingsState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: state.permissions.asMap().entries.map((entry) {
          final index = entry.key;
          final permission = entry.value;

          return Column(
            children: [
              if (index > 0)
                const Divider(color: AppColors.backgroundLight, height: 1),
              _buildPermissionTile(context: context, permission: permission),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionTile({
    required BuildContext context,
    required PermissionInfo permission,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (permission.isGranted ? AppColors.success : AppColors.warning)
              .withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          permission.isGranted
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          color: permission.isGranted ? AppColors.success : AppColors.warning,
        ),
      ),
      title: Text(
        permission.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        permission.description,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: permission.isGranted
          ? const Text(
              'Granted',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            )
          : ElevatedButton(
              onPressed: () async {
                await context.read<SettingsCubit>().requestPermission(
                  permission,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Grant', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}
