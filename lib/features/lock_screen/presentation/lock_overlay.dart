import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/constants.dart';

/// Entry point for the lock screen overlay
/// This widget runs in a separate isolate when the overlay is shown
class LockOverlay extends StatefulWidget {
  const LockOverlay({super.key});

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _remainingSeconds = 0;
  Timer? _timer;

  // Math challenge state
  bool _showMathChallenge = false;
  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;
  String _userAnswer = '';
  String? _errorMessage;
  int _attemptCount = 0;
  static const int _maxAttempts = 3;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Start countdown
    _initializeAndStartCountdown();
  }

  Future<void> _initializeAndStartCountdown() async {
    // Small delay to ensure SharedPreferences is written by main app
    await Future.delayed(const Duration(milliseconds: 300));

    // Get initial remaining time from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _remainingSeconds = prefs.getInt('remaining_time_seconds') ?? 0;

    if (mounted) {
      setState(() {});
    }

    // Start self-running countdown (not reading from prefs every second)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        // Auto close overlay when timer reaches 0
        await FlutterOverlayWindow.closeOverlay();
        return;
      }

      // Decrement locally and save to prefs
      _remainingSeconds--;

      // Save to SharedPreferences so main app can read it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('remaining_time_seconds', _remainingSeconds);

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _generateMathChallenge() {
    // Generate random numbers for multiplication (2-12 range for reasonable difficulty)
    _num1 = _random.nextInt(11) + 2; // 2-12
    _num2 = _random.nextInt(11) + 2; // 2-12
    _correctAnswer = _num1 * _num2;
    _userAnswer = '';
    _errorMessage = null;
    _attemptCount = 0;
  }

  void _showUnlockChallenge() {
    _generateMathChallenge();
    setState(() {
      _showMathChallenge = true;
    });
  }

  void _onNumberPressed(String number) {
    if (_userAnswer.length < 4) {
      setState(() {
        _userAnswer += number;
        _errorMessage = null;
      });
    }
  }

  void _onDeletePressed() {
    if (_userAnswer.isNotEmpty) {
      setState(() {
        _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _userAnswer = '';
      _errorMessage = null;
    });
  }

  void _checkAnswer() {
    final userAnswer = int.tryParse(_userAnswer);

    if (userAnswer == null || _userAnswer.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan jawaban!';
      });
      return;
    }

    if (userAnswer == _correctAnswer) {
      // Correct answer - close overlay
      _closeOverlay();
    } else {
      _attemptCount++;
      if (_attemptCount >= _maxAttempts) {
        // Max attempts reached, generate new question
        setState(() {
          _errorMessage = 'Salah $_maxAttempts kali! Soal baru...';
        });
        Future.delayed(const Duration(seconds: 1), () {
          _generateMathChallenge();
          if (mounted) setState(() {});
        });
      } else {
        setState(() {
          _errorMessage =
              'Salah! Coba lagi (${_maxAttempts - _attemptCount} kesempatan)';
        });
      }
      _userAnswer = '';
    }
  }

  Future<void> _closeOverlay() async {
    // Clear remaining time to signal unlock
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining_time_seconds', 0);
    await prefs.setInt('current_phase', 0); // Set to idle
    await prefs.setBool('is_running', false);

    // Close the overlay
    await FlutterOverlayWindow.closeOverlay();
  }

  void _cancelChallenge() {
    setState(() {
      _showMathChallenge = false;
      _errorMessage = null;
      _userAnswer = '';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.lockScreenGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _showMathChallenge
                      ? _buildMathChallengeUI()
                      : _buildLockScreenUI(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockScreenUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lock icon
        _buildLockIcon(),
        const SizedBox(height: 32),

        // Title
        const Text(
          AppStrings.lockScreenTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),

        // Message
        const Text(
          AppStrings.lockScreenMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // Timer display
        _buildTimerDisplay(),
        const SizedBox(height: 32),

        // Motivation message
        _buildMotivationCard(),
        const SizedBox(height: 24),

        // Unlock button
        _buildUnlockButton(),
      ],
    );
  }

  Widget _buildMathChallengeUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Math icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.calculate_rounded,
            size: 48,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        const Text(
          'Jawab Soal Ini!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Math question
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Text(
            '$_num1 × $_num2 = ?',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Answer display
        Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Text(
            _userAnswer.isEmpty ? '???' : _userAnswer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _userAnswer.isEmpty
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Custom number pad
        _buildNumberPad(),
        const SizedBox(height: 16),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel button
            TextButton(
              onPressed: _cancelChallenge,
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            // Submit button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _checkAnswer,
                  borderRadius: BorderRadius.circular(24),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'JAWAB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberPad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton('C', _onClearPressed, AppColors.warning),
              _buildNumberButton('0'),
              _buildActionButton('⌫', _onDeletePressed, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.breakTimeColor.withValues(alpha: 0.2),
        border: Border.all(
          color: AppColors.breakTimeColor.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: const Icon(
        Icons.bedtime_rounded,
        size: 56,
        color: AppColors.breakTimeColor,
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.breakTimeColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _formattedTime,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 64,
              fontWeight: FontWeight.w200,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'until screen unlocks',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              AppStrings.lockScreenMotivation,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showUnlockChallenge,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'BUKA KUNCI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
