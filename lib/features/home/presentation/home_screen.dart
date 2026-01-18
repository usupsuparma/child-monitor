import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/constants.dart';
import '../../settings/presentation/settings_screen.dart';
import '../cubit/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.lockScreenGradient),
        child: SafeArea(
          child: BlocConsumer<HomeCubit, HomeState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.read<HomeCubit>().clearError();
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(child: _buildTimerSection(context, state)),
                  _buildControls(context, state),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(state),
            ],
          ),
          _buildSettingsButton(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(HomeState state) {
    final timerState = state.timerState;

    String statusText;
    Color statusColor;

    if (timerState.isIdle) {
      statusText = 'Ready';
      statusColor = AppColors.idleColor;
    } else if (timerState.isScreenTime) {
      statusText = AppStrings.screenTimeLabel;
      statusColor = AppColors.screenTimeColor;
    } else {
      statusText = AppStrings.breakTimeLabel;
      statusColor = AppColors.breakTimeColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          if (context.mounted) {
            context.read<HomeCubit>().refreshPermissions();
          }
        },
        icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTimerSection(BuildContext context, HomeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimerRing(context, state),
          const SizedBox(height: 32),
          _buildPhaseInfo(context, state),
        ],
      ),
    );
  }

  Widget _buildTimerRing(BuildContext context, HomeState state) {
    final timerState = state.timerState;
    final progress = timerState.isIdle ? 0.0 : timerState.progress;

    Color progressColor;
    if (timerState.isScreenTime) {
      progressColor = AppColors.screenTimeColor;
    } else if (timerState.isBreakTime) {
      progressColor = AppColors.breakTimeColor;
    } else {
      progressColor = AppColors.primary;
    }

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: AppColors.surfaceDark.withOpacity(0.3),
              color: AppColors.surfaceDark.withOpacity(0.3),
            ),
          ),
          // Progress ring
          SizedBox(
            width: 280,
            height: 280,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: value,
                    color: progressColor,
                    strokeWidth: 12,
                  ),
                );
              },
            ),
          ),
          // Timer text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timerState.isIdle
                    ? _formatDuration(state.settings.screenTime)
                    : timerState.formattedTime,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              if (!timerState.isIdle)
                Text(
                  timerState.isPaused ? 'PAUSED' : 'REMAINING',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              if (timerState.isIdle)
                Text(
                  'TAP START',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPhaseInfo(BuildContext context, HomeState state) {
    final timerState = state.timerState;

    if (timerState.isIdle) {
      return Column(
        children: [
          Text(
            'Screen Time: ${state.settings.screenTime.inMinutes} min',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Break Time: ${state.settings.breakTime.inMinutes} min',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      );
    }

    final phaseText = timerState.isScreenTime
        ? 'Screen Time Active'
        : 'Break Time - Take a Rest!';

    final phaseIcon = timerState.isScreenTime
        ? Icons.phone_android
        : Icons.bedtime_outlined;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(phaseIcon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          phaseText,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, HomeState state) {
    final timerState = state.timerState;
    final cubit = context.read<HomeCubit>();

    if (timerState.isIdle) {
      // Show start button
      return _buildGradientButton(
        onPressed: () => cubit.startTimer(),
        gradient: AppColors.successGradient,
        icon: Icons.play_arrow_rounded,
        label: 'START',
      );
    }

    if (timerState.isPaused) {
      // Show resume and stop buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGradientButton(
            onPressed: () => cubit.resumeTimer(),
            gradient: AppColors.successGradient,
            icon: Icons.play_arrow_rounded,
            label: 'RESUME',
          ),
          const SizedBox(width: 16),
          _buildGradientButton(
            onPressed: () => cubit.stopTimer(),
            gradient: AppColors.dangerGradient,
            icon: Icons.stop_rounded,
            label: 'STOP',
            small: true,
          ),
        ],
      );
    }

    // Show pause and stop buttons
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGradientButton(
          onPressed: () => cubit.pauseTimer(),
          gradient: AppColors.primaryGradient,
          icon: Icons.pause_rounded,
          label: 'PAUSE',
        ),
        const SizedBox(width: 16),
        _buildGradientButton(
          onPressed: () => cubit.stopTimer(),
          gradient: AppColors.dangerGradient,
          icon: Icons.stop_rounded,
          label: 'STOP',
          small: true,
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required Gradient gradient,
    required IconData icon,
    required String label,
    bool small = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 24 : 40,
              vertical: small ? 12 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: small ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: small ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
